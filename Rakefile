# encoding: utf-8
require 'rake'
require 'tempfile'
require 'uri'
require 'nokogiri'
require 'csv'
require 'colorize'

$list=Dir.glob "*.xml"

# extending functionality of a class
class Nokogiri::XML::Element
  def empty?
    if self.content == "" || self.children.length < 1
      then return true
      else return false
    end
  end
end

# utility methods
def prune(list, name)
  name = name || String.new
  new_list = Array.new
  raise ArgumentError, "Nothing named #{name} exists!" unless File.exist? name
  raise ArgumentError, "#{list} should be a Array!" unless list.kind_of? Array
  if File.file?(name)
    new_list = list.reject {|k| k != name }
  elsif File.directory?(name)
    new_list = list.reject { |k| ! k.match( name ) }
  else
    new_list = list
  end
end

def prepend_ns(xpath_string)
  xpath_string.gsub(/\/(\w+)/, '/xmlns:\1')
end

def build_extent(doc, str=nil)
  content = str || "1 amorphous blob."
  extent = Nokogiri::XML::Node.new "extent", doc
  extent.content = content
  return extent
end

#tasks
desc "searches TEI files with xpath, reporting nulls"
task :xpath, [ :fn, :xpath ]  do |t,args|
  puts "fn: #{args[:fn]}"
  name = args[:fn] || ""
  xpath = args[:xpath] || "/ead/archdesc/did/physdesc[1]"
  xpath = prepend_ns(xpath) unless xpath.match("xmlns")
  $list = prune($list, name) unless name == ""
  puts "scanning #{$list.length} file(s) for \033[37m #{xpath} \033[0m ..."
  $list.each do |item|
    xml = Nokogiri::XML(File.open(item))
    nodeset = xml.xpath(xpath)
    if nodeset.empty?
      puts "xpath search of #{item} yielded nothing." 
    else
      puts nodeset.to_xml.blue
    end
  end
end

desc "adds <extent> element in sed-like manner"
task :add_sedlike_extent, [ :fn ] do |t,args|
  name = args[:fn] || "" 
  xpath = "/xmlns:ead/xmlns:archdesc/xmlns:did/xmlns:physdesc"
  $list = prune($list, name) unless name == ""
  $list.each do |item|
    xml = Nokogiri::XML(File.open(item))
    nodeset = xml.xpath(xpath)
    if nodeset.length == 0
      puts "#{item} has nothing matching \033[37m #{xpath} \033[0m"
    elsif nodeset.length == 1 && nodeset.first.empty?
      puts "#{item} adding <extent> data"
      new_node = build_extent(xml)
      puts "#{new_node.to_xml}".yellow
      file = Tempfile.new('sed-stream')

      # read file as stream and process selected line
      File.open(item, 'r') do |f|
        while line = f.gets
          if line.match( /(<physdesc label="Physical Characteristics" encodinganalog="300\$a")\/>/)
          then
            match = line.match( /(\s+<physdesc label="Physical Characteristics" encodinganalog="300\$a")\/>/)
            new_line = "#{match[1]}>#{new_node.to_xml}</physdesc>\n"
            file.write(new_line)
          else
            file.write(line)   
          end
        end
      end

      file.write("") # makes for cleaner diffs
      file.close
      system "mv #{file.path} #{item}"
    elsif nodeset.length != 1
      puts "#{item} #{nodeset.length} nodes found"
    else 
      puts "first.empty? returned #{nodeset.first.empty?}."
    end
  end
end

desc "add extent where no <physdesc> exists (sed)"
task :add_extent_de_novo, [ :fn ] do |t,args|
  sed_script="script01.sed"
  name = args[:fn] || "" 
  $list = prune($list, name) unless name == ""
  $list.each do |item|
    test = %x[ grep '1 amorphous blob' "#{item}" ]
    if test == ""
      %x[ sed -i '' -E -f "#{sed_script}" "#{item}" ]
    else
      puts "file already contains #{test.strip}".yellow
      puts "skipping #{item}".blue
    end
  end
  system "git status -s"
end


desc "removes empty <persname> elements, using sed"
task :strip_empty_persnames, [ :fn ] do |t,args|
  name = args[:fn] || "" 
  $list = prune($list, name) unless name == ""
  $list.each do |item|
    %x[ sed -E -e 's#\s+<persname[^>]+/>##'  "#{item}" >result.xml ]
    system "mv result.xml #{item}"
    system "git status -s #{item}"
  end
end

desc "removes empty <unitdate> elements, using sed"
task :strip_empty_dates, [ :fn ] do |t,args|
  name = args[:fn] || "" 
  $list = prune($list, name) unless name == ""
  $list.each do |item|
    %x[ sed -E -e 's#<unitdate[^>]+/>##'  "#{item}" >result.xml ]
    system "mv result.xml #{item}"
    system "git status -s #{item}"
  end
end

desc "display files with empty <unitdate> elements"
task :dates? do
  system "grep -l -E '<unitdate[^>]+/>' viu*.xml "
end

desc "display files with empty <container> elements"
task :containers? do
  system "grep -l -E '<container[^>]+/>' viu*.xml "
end

desc "reports on files missing archdesc/did/extent (required)"
task :extent? do
  xpath = "/xmlns:ead/xmlns:archdesc/xmlns:did/xmlns:physdesc/xmlns:extent[1]/text()"
  #xpath = "/xmlns:ead/xmlns:archdesc/xmlns:did/xmlns:physdesc"
  puts "These files need fixing:".yellow
  $list.each do |item|
    xml = Nokogiri::XML(File.open(item))
    nodeset = xml.xpath(xpath)
    if nodeset.empty?
      puts "#{item}".colorize( :blue )
    end
  end
end

desc "removes empty <container> elements, using sed"
task :strip_empty_containers, [ :fn ] do |t,args|
  name = args[:fn] || ""
  $list = prune($list, name) unless name == ""
  $list.each do |item|
    %x[ sed -i '' -E -e 's#<container[^>]+/>##' "#{item}" ]
    system "git status -s #{item}"
 end
end

desc "display shell info"
task :shell do
  puts "#{ ENV['SHELL'] }"
end

desc "adds <extent> element for archival description"
task :add_extent, [ :fn ] do |t,args|
  name = args[:fn] || "" 
  xpath = "/xmlns:ead/xmlns:archdesc/xmlns:did/xmlns:physdesc"
  $list = prune($list, name) unless name == ""
  $list.each do |item|
    xml = Nokogiri::XML(File.open(item))
    nodeset = xml.xpath(xpath)
    if nodeset.length == 0
      puts "#{item} has nothing matching \033[37m #{xpath} \033[0m"
    elsif nodeset.length == 1 && nodeset.first.empty?
      puts "#{item} adding <extent> data"
      new_node = build_extent(xml)
      puts "#{new_node.to_xml}".yellow
      nodeset.first.add_child(new_node)
      puts "#{nodeset.first.to_xml}".green
      file = Tempfile.new('extent')
      file.write(xml.to_xml)
      file.close
      system "mv #{file.path} #{item}"
    elsif nodeset.length != 1
      puts "#{item} #{nodeset.length} nodes found"
    else 
      puts "first.empty? returned #{nodeset.first.empty?}."
    end
  end
end
