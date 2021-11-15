#!/usr/bin/env ruby
# Bandage solution to update the annotaions YAML until I find something better
require 'yaml'

ANNOTATIONS_FILE = 'bundle/metadata/annotations.yaml'

annotations_file_yaml = YAML.load_file(ANNOTATIONS_FILE)

annotations_file_yaml['annotations']['com.redhat.delivery.backport'] = true
annotations_file_yaml['annotations']['com.redhat.delivery.operator.bundle'] = true
annotations_file_yaml['annotations']['com.redhat.openshift.versions'] = 'v4.6'

File.open(ANNOTATIONS_FILE, 'w') { |f| YAML.dump(annotations_file_yaml, f) }
