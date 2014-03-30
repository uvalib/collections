#!/bin/env ruby

require 'nokogiri'
require 'json'

def get_structure(node, hash)

  children = node.xpath("*[starts-with(local-name(), 'c0')]")
  if children != []
    puts "so far so good."
    children.each_with_index do |c,index| 
      key = index.to_s.to_sym
      hash[key] = get_structure(c, {})
    end
  end
  return hash
end

def get_json(string)
  parsed = JSON.parse(string)
end

def get_json_structure(list, new_hash) 
  if list.kind_of?(Hash)
    new_hash = get_hash_data(list, new_hash)
  elsif list.kind_of?(Array)
    new_hash = get_array_data(list, new_hash)   
  end
  return new_hash
end

def get_hash_data(list, new_hash)
  if list.kind_of? Hash
    list.keys.sort.each_with_index { |key,index| # only works b/c we pidded in order!
      new_hash = get_array_data( list[key], {})
    }
  else
    new_hash = {}
  end
  return new_hash
end

def get_array_data(list, new_hash)
  if list.kind_of? Array
    list.each_with_index { |c,index|
      unless c.kind_of? Array
        key = index.to_s.to_sym
        new_hash[key] = get_hash_data( c, {} )
      end
    }
  else
    new_hash = {}
  end
  return new_hash
end

class Hash
  def show_structure(pad="")
    self.keys.map(&:to_s).map(&:to_i).sort.each { |k|
      puts "#{pad}#{k}: #{self[k.to_s.to_sym].count}"
      self[k.to_s.to_sym].show_structure(pad + "  ")
    }
  end
end

def get_my_did(element)
  if element.is_a? Nokogiri::XML::Element
    element.xpath("did").first
  elsif element.is_a? Nokogiri::XML::NodeSet
    element.first.xpath("did").first
  end
end

def make_unitid(pid, xmldoc) #use add_next_sibling after did/unittitle
  unitid = Nokogiri::XML::Node.new 'unitid', xmldoc
  unitid[:label]="Digital Repository PID"
  unitid[:repositorycode]="ViU-H"
  unitid[:countrycode]="us"
  unitid.content=pid
  unitid
end

# get the first c01 pid
# parsed["uva-lib:2221992"].map(&:keys).first
# list_of_pids = parsed["uva-lib:2221992"].map(&:keys) ; list_of_pids.flatten!
def get_list_of_pids(pid, hash)
  if hash[pid].is_a? Hash
    hash[pid].map(&:keys).flatten!
  elsif hash[pid].is_a? Array
    hash[pid].reduce([]) do |r,i| r << i.keys.first; r end
  else
    nil
  end
end

def add_unitid_to_dids(nodeset, list_of_pids, array_of_pids, xmldoc)
  puts "tackling list (#{nodeset.count} nodes)"
  if nodeset.count == list_of_pids.count
    nodeset.each_with_index do |element,index|
      # add pid as unitid after unititle in did element
      raise RuntimeError, "no did/unittitle found on element ##{index}" unless element.xpath("did/unittitle") != []
      current_pid = list_of_pids[index]
      new_id_node = make_unitid(current_pid, xmldoc)
      element.xpath("did/unittitle").first.add_next_sibling new_id_node
      
      # traverse json structure (hashes/arrays), lookup current PID, and recurse
      one_element_hash = array_of_pids[index]; key = one_element_hash.keys.first
      puts "Good sign: pid matches hash key sought (#{current_pid})" if current_pid == key
      raise RuntimeError, "encountered hash with #{one_element_hash.keys.count} keys at #{index}" unless one_element_hash.keys.count == 1

      new_array_of_pids = one_element_hash[key]
      new_list_of_pids = get_list_of_pids(current_pid, one_element_hash)
      puts "new_list_of_pids is #{new_list_of_pids.class}"
      next if new_list_of_pids.nil?
      puts "trying to recurse on  #{new_list_of_pids}"
      puts "#{new_list_of_pids.count} pids.  First one is #{new_list_of_pids.first}"
      
      new_nodeset = element.xpath("*[starts-with(local-name(), 'c0')]")
      puts "Got #{new_nodeset.length} subordinate components" if new_nodeset != []
      if new_nodeset != [] && new_list_of_pids != nil && new_array_of_pids != [] && new_list_of_pids != []
        puts "recursing...."
        add_unitid_to_dids(new_nodeset, new_list_of_pids, new_array_of_pids, xmldoc)
      end
    end
  end
  return true
end

def prep_objects(fn)
  xml=Nokogiri::XML(File.open(fn)); nil
  xml.remove_namespaces!; nil
  dsc = xml.xpath("//dsc").first; nil
  nodeset = dsc.xpath("*[starts-with(local-name(), 'c0')]"); nil
  return xml, dsc, nodeset, 0
end

if nodeset.count == list_of_pids.count
  nodeset.each_with_index do |element,index|
    puts list_of_pids[index]
  end
  nil
end
