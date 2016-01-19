#!/usr/bin/python

import argparse
from os import path
from subprocess import call


def _qc(args):
	"""
	Performs QC pipeline
	
	:param args: input qc pipeline files
	"""
	
	# Verify that bam index file is present, create it if not
	if not path.isfile(args.bam + '.bai'):
		print 'Creating BAM index file..'
		call(['samtools', 'index', args.bam])
	
	# Verify that reference index file is present, create it if not
	if not path.isfile(args.reference + '.fai'):
		print 'Creating reference index..'
		call(['samtools', 'faidx', args.reference])
	
	# Run SeqUtils strandcoverage and save result
	print 'Run SeqUtils strandcoverage util..'
	call(['sequtils.sh', 'strandcoverage', args.bam, args.bed, '/mnt/pipeline-results/strandcoverage.bed'])
	
	# Process input bed file to unite overlapped regions
	print 'Process overlapped regions..'
	call(['sequtils.sh', 'bedunite', args.bed, args.bed])
	
	# Run standalone Torrent Suite Variant Caller
	call(['variant_caller_pipeline.py', '-i', args.bam, '-b', args.bed, '-r', args.reference, '-p', args.parameters, '-o', '/mnt/tvc-output'])
	
	# and save the result
	call(['cp', '/mnt/tvc-output/TSVC_variants.vcf', '/mnt/pipeline-results/'])
	call(['cp', '/mnt/tvc-output/all.log', '/mnt/pipeline-results/'])
	


if __name__ == '__main__':
	parser = argparse.ArgumentParser(prog='QC pipeline', description='Usage message for QC pipeline script')
	subparsers = parser.add_subparsers(help='Pipeline commands help')
	
	start_cmd = subparsers.add_parser('start', help='Start QC pipeline command')
	start_cmd.add_argument('-b', '--bam', help='Input BAM file', required=True)
	start_cmd.add_argument('-r', '--bed', help='Input BED file of regions', required=True)
	start_cmd.add_argument('-f', '--reference', help='File of reference', required=True)
	start_cmd.add_argument('-p', '--parameters', help='File with variant caller parameters', required=True)
	start_cmd.set_defaults(func=_qc)
	
	args = parser.parse_args()
	args.func(args)

