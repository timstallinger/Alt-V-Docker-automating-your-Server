let util = require('util');
let exec = require('child_process').exec;
let spawn = require('child_process').spawn;
let process = require('process');
let fs = require('fs');

let vars = require('./vars.json');

function run(command, args, output = null, cwd = undefined, env = undefined) {
	return new Promise((resolve, reject) => {
		let stdio =
			output == 'stream'
				? ['ignore', process.stdout, process.stderr]
				: output == 'buffer'
					? ['ignore', 'pipe', 'pipe']
					: 'ignore';

		let options = {
			shell: true,
			stdio: stdio,
			cwd: cwd,
			env: env
		};

		let proc = spawn(command, args, options);

		if (output == 'buffer') {
			let stdout = '';
			let stderr = '';

			proc.stdout.on('data', data => {
				stdout += data.toString();
			});

			proc.stderr.on('data', data => {
				stderr += data.toString();
			});

			proc.on('close', exit => {
				resolve({ exit: exit, stdout: stdout, stderr: stderr });
			});
		} else {
			proc.on('close', exit => {
				resolve({ exit: exit });
			});
		}
	});
}

function important(s) {
	return `\x1b[30;46m${s}\x1b[0m`;
}

async function main() {
	// check if node_modules exists
	if (!fs.existsSync(`${vars.source_dir}/node_modules`)) {
		console.log(important("• node_modules not present; npm install'ing!"));
		await run('npm', ['install'], 'stream');
	}

	// cleanup server directory
	console.log(
		important('• cleaning server directory and creating new structure')
	);
	await run('cmd', [
		'/C',
		`rmdir ${vars.server_dir} /S /Q & ` +
		`mkdir ${vars.server_dir}/resources/${vars.resource_name}/ & ` +
		`mklink /J ${vars.server_dir}/resources/${
		vars.resource_name
		}/node_modules ${vars.source_dir}/node_modules`
	]);

	// copy files
	console.log(important('• copying static files'));
	await Promise.all(
		[
			`robocopy ${vars.source_dir}/client ${vars.server_dir}/resources/${
			vars.resource_name
			}/client /S`,
			`robocopy ${vars.altv_dir} ${vars.server_dir} /S`,
			`copy ${vars.source_dir}/resource.cfg ${vars.server_dir}/resources/${
			vars.resource_name
			} `
		].map(copy => run('cmd', ['/C', copy]))
	);

	// build typescript
	console.log(important('• building typescript'));
	let build_server = run(
		'npx',
		[
			'tsc',
			'--pretty',
			`-p ${vars.source_dir}/server/tsconfig.json`,
			`--outDir ${vars.server_dir}/resources/${vars.resource_name}/server`
		],
		'stream'
	);
	await build_server;

	// change port in config

	// launch server
	console.log(important('• launching server'));
	await run(
		`chmod +x ${vars.server_dir}/start.sh && chmod +x ${vars.server_dir}/altv-server && sudo ${vars.server_dir}/start.sh`,
		[],
		'stream',
		vars.server_dir
	);
}

main();
