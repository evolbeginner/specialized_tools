#! /bin/env ruby

# download files from PLAZA v3.0
# original name: "download_plaza.rb"

require 'getoptlong'
require 'Dir'
require 'fileutils'


######################################################################
def read_infile(infile, cols)
  elements = Hash.new{|h,k|h[k]={}}
  categories = %w[Species CDS Protein Genome]
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    #species, cds_file, protein_file, genome_file = line.split("\t")
    line_array = line.split("\t")
    next if line_array[0] == 'Species'
    cols.each do |col|
      name = line_array[col].split(' ')[0]
      parent_name = nil
      if categories[col] == 'Genome'
          parent_name = 'Genomes'
      else
          parent_name = 'Fasta'
      end      
      resource_file = File.join([Download_address_prefix, parent_name, name])
      elements[categories[col]][resource_file] = ''
    end
  end
  return(elements)
end


def download_plaza(elements, outdir, is_overlap)
  elements.each_pair do |ele, value|
    if not File.exist?(File.join(outdir,ele))
      FileUtils.mkdir_p(File.join(outdir,ele))
    end
    value.each_key do |file|
      basename = File.basename(file)
      is_download = true
      outfile = File.join([outdir, ele, basename]) 
      if File.exist?(outfile)
        if is_overlap
          is_download = true
        else
          is_download = false
          puts "outfile #{outfile} has already existed! Skipping ......"
        end
      else
        is_download = true
      end

      if is_download
        puts outfile
        `wget #{file} -O #{outfile} -q`
        puts "wget #{file} -O #{outfile} -q"
      end

    end
  end
end


######################################################################
Download_address_prefix_0 = "ftp://ftp.psb.ugent.be/pub/plaza/"

infile = nil
cols = Array.new
outdir = nil
is_force = false
is_overlap = false
type = nil


opts = GetoptLong.new(
  ['--list', '--infile', GetoptLong::REQUIRED_ARGUMENT],
  ['--col', GetoptLong::REQUIRED_ARGUMENT],
  ['--outdir', GetoptLong::REQUIRED_ARGUMENT],
  ['--force', GetoptLong::NO_ARGUMENT],
  ['--overlap', GetoptLong::NO_ARGUMENT],
  ['--type', GetoptLong::REQUIRED_ARGUMENT],
)

opts.each do |opt,value|
  case opt
    when '--list', '--infile'
      infile = value
    when '--col'
      value.split(',').each do |i|
        cols.push(i.to_i-1)
      end
    when '--outdir'
      outdir = value
    when '--force'
      is_force = true
    when '--overlap'
      is_overlap = true
    when '--type'
      type = value
  end
end


if infile.nil?
  raise "infile has not been given! Exiting ......"
elsif outdir.nil?
  raise "outdir has not been given! Exiting ......"
elsif type.nil?
  raise "type has not been given! Exiting ......"
end


if cols.empty?
  cols = [1,2,3]
end


if type == "monocot"
  Download_address_prefix = Download_address_prefix_0 + "/plaza_public_monocots_03"
elsif type == "dicot"
  Download_address_prefix = Download_address_prefix_0 + "/plaza_public_dicots_03"
else
  raise "type has to be either 'dicot' or 'monocot'. Exiting ......"
end


if ! File.exist?(outdir)
  FileUtils.mkdir_p(outdir)
else
  if is_force
    `rm -rf #{outdir}`
  end
end


######################################################################
elements = read_infile(infile, cols)

download_plaza(elements, outdir, is_overlap)


