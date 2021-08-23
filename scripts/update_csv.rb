#!/usr/bin/env ruby
# Bandage solution to update the CSV YAML until I find something better
require 'time'
require 'yaml'

MANIFEST_FILE = 'config/manifests/bases/pcc-operator.clusterserviceversion.yaml'

manifest_file_yaml = YAML.load_file(MANIFEST_FILE)

manifest_file_yaml['metadata']['annotations']['containerImage'] = ARGV[0]
manifest_file_yaml['metadata']['annotations']['createdAt'] = Time.now.strftime('%Y-%m-%d')

File.open(MANIFEST_FILE, 'w') { |f| YAML.dump(manifest_file_yaml, f) }
