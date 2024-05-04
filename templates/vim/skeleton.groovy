#!/usr/bin/env groovy

import groovy.cli.commons.CliBuilder
import groovy.json.JsonSlurper
import groovy.transform.Field
import java.nio.file.*

@Field boolean dry_run
@Field boolean be_verbose

parse_command_line_options()

// === === === === ===
// ===  UTILITIES  ===
// === === === === ===

void parse_command_line_options() {
	def script_name = getClass().getSimpleName() + '.groovy'
	def script_version = '1.0'

	// parse command line options:
	def cli = new CliBuilder(
		usage : "$script_name [options] <album-info json file>",
		header: 'Options:',
		footer: 'Convert WAV files as created by cdda2wav to FLAC and add metadata.'
	)
	cli.d(longOpt: 'dry-run', 'dry run (just show info / verify config file content)')
	cli.h(longOpt: 'help', 'print this message')
	cli.j(longOpt: 'json', args:1, argName:'num_tracks', type:Integer,
				'print a template JSON config file for the given number of tracks to [ stdout | <outfile.json> ]')
	cli.v(longOpt: 'verbose', 'be verbose')
	cli.V(longOpt: 'version', 'show version and exit')
	def options = cli.parse(args)

	// evaluate command line options:
	if (!options) _exit (1, 'Error parsing command line options')
	if (options.h) { cli.usage() ; _exit() }
	if (options.V) { println "$script_name : $script_version" ; _exit() }

	final int n = options.arguments().size()

	if (!options.j && n != 1) {
		cli.usage()
		_exit (2, 'Invalid command line options')
	}

	dry_run = options.d
	be_verbose = options.v

	if (n == 1) {
		config_file = Paths.get(options.arguments()[0])
		println "Using configuration file »${config_file}«"
	}

	// perform actions:
	if (options.j) {
		generate_template(options.j)
	} else
	if (n == 1) {
		convert()
	}
}

void runCommand(String[] cmdArgs) {
	if (be_verbose) {
		print 'Executing:'
		for (arg in cmdArgs) printf ("  »%s«%n", arg)
	}
	if (!dry_run) new ProcessBuilder(cmdArgs).inheritIO().start().waitFor()
}

/** Exit the script successfully (that is returning 0). */
static void _exit() {
	System.exit 0
}

/** Exit the script with the given error code and message. */
static void _exit(int errorCode, Object message) {
	println message
	System.exit errorCode
}

