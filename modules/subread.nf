/* ------------ subread -----------
https://subread.sourceforge.net/SubreadUsersGuide.pdf
*/

/*
* To index
*/ 
process subread_index {
    label 'subread'
    tag "$genome_fasta"
    publishDir "${params.outdir}/${outpath}", mode: 'copy'

    input:
        path(genome_fasta)
        val outpath

    output:
        path("*")

    script:

        """
        subread-buildindex -o ${genome_fasta.baseName}_index ${genome_fasta}
        """
}

/*
* To align with graphmap2
*/
process subread {
    label 'subread'
    tag "$sample"
    publishDir "${params.outdir}/${outpath}", pattern: "*subread.vcf", mode: 'copy'

    input:
        tuple val(sample), path(fastq), val(library)
        path genome
        path index
        val outpath

    output:
        tuple val(sample), path ("*.bam"), emit: tuple_sample_bam, optional:true
        path "*subread.vcf", emit: subread_vcf, optional:true

    script:

        // set input according to short_paired parameter
        def input = "-r ${fastq[0]}"
        if (params.read_type == "short_paired"){
            input =  "-r ${fastq[0]} -R ${fastq[1]}"
        }

        // remove fastq.gz
        def fileName = fastq[0].baseName.replace('.fastq','')
        
        // prepare index name
        def index_prefix = genome.baseName + "_index"

        // deal with library type
        def read_orientation=""
        if (! params.subread_options.contains("-S ") &&
            params.read_type == "short_paired" && 
            ! params.skip_libray_usage){ // only if -S is not set and if we are not skipping library usage
            if (library.contains("M") ){
                read_orientation = "-S ff"
            } else if (library.contains("O") ) {
                read_orientation = "-S rf"
            } else if (library.contains("I") ) {
                read_orientation = "-S fr"
            } 
        }
        """
        subread-align -T ${task.cpus} ${read_orientation} -i ${index_prefix} ${input} -o ${fileName}.bam --sortReadsByCoordinates ${params.subread_options}
        """
}