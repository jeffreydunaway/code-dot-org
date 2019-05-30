#!/usr/bin/env ruby

# Pulls in all strings that need to be translated. Pulls source
# files from blockly-core, apps, pegasus, and dashboard
# as well as instructions for levelbuilder supported levels and
# collects them to the single source folder i18n/locales/source.

require File.expand_path('../../../dashboard/config/environment', __FILE__)
require File.expand_path('../../../pegasus/src/env', __FILE__)
require 'fileutils'
require 'json'
require 'yaml'
require 'tempfile'

require_relative 'i18n_script_utils'

def sync_in
  localize_level_content
  localize_block_content
  run_bash_script "bin/i18n-codeorg/in.sh"
  redact_level_content
  redact_block_content
end

def copy_to_yml(label, data)
  File.open("dashboard/config/locales/#{label}.en.yml", "w+") do |f|
    f.write(to_crowdin_yaml({"en" => {"data" => {label => data}}}))
  end
end

# sanitize a string before uploading to crowdin. Currently only performs
# CRLF -> LF conversion, but could be extended to do more
def sanitize(string)
  return string.gsub(/\r(\n)?/, "\n")
end

def redact_translated_data(path, plugins = nil)
  source = "i18n/locales/source/#{path}"
  backup = "i18n/locales/original/#{path}"
  FileUtils.mkdir_p(File.dirname(backup))
  FileUtils.cp(source, backup)
  redact(source, source, plugins)
end

def redact_block_content
  redact_translated_data('dashboard/blocks.yml', 'blockfield')
end

def get_dsl_i18n_strings(level)
  return {} unless level.is_a?(DSLDefined)
  text = level.dsl_text
  return {} unless text
  _, i18n = level.class.dsl_class.parse(text, '')
  i18n
end

def localize_level_content
  # Rewrite autogenerated 'dsls.en.yml' i18n file with new master-copy English strings
  yml_file = Rails.root.join("config/locales/dsls.en.yml")
  dsl_i18n_strings = {}

  # We have to run this specifically from the Rails directory because
  # get_dsl_i18n_strings relies on level.dsl_text which relies on
  # level.filename which relies on running a shell command
  Dir.chdir(Rails.root) do
    Script.all.each do |script|
      next unless ScriptConstants.i18n? script.name

      script_strings = {
        "display_name" => {},
        "short_instructions" => {},
        "long_instructions" => {},
        "failure_message_overrides" => {},
        "authored_hints" => {},
        "callouts" => {},
        "block_categories" => {},
        "function_names" => {}
      }

      script.levels.each do |level|
        url = get_level_url_key(script, level)
        if level.is_a?(DSLDefined)
          level.contained_levels.each do |contained_level|
            dsl_i18n_strings.deep_merge! get_dsl_i18n_strings(contained_level)
          end

          dsl_i18n_strings.deep_merge! get_dsl_i18n_strings(level)
        else
          # display_name
          if level.display_name
            script_strings['display_name'][url] = level.display_name
          end
          # short_instructions
          if level.short_instructions
            script_strings['short_instructions'][url] = level.short_instructions
          end
          # long_instructions
          if level.long_instructions
            script_strings['long_instructions'][url] = level.long_instructions
          end

          # failure_message_overrides
          if level.class <= Blockly && level.failure_message_override
            script_strings['failure_message_overrides'][url] = level.failure_message_override
          end

          # authored_hints
          if level.authored_hints
            authored_hints = JSON.parse(level.authored_hints)
            script_strings['authored_hints'][url] = Hash.new unless authored_hints.empty?
            authored_hints.each do |hint|
              script_strings['authored_hints'][url][hint['hint_id']] = hint['hint_markdown']
            end
          end
          # callouts
          if level.callout_json
            callouts = JSON.parse(level.callout_json)
            script_strings['callouts'][url] = Hash.new unless callouts.empty?
            callouts.each do |callout|
              script_strings['callouts'][url][callout['localization_key']] = callout['callout_text']
            end
          end

          level_xml = Nokogiri::XML(level.to_xml, &:noblanks)
          blocks = level_xml.xpath('//blocks').first
          if blocks
            ## Categories
            block_categories = blocks.xpath('//category')
            script_strings['block_categories'][url] = Hash.new unless block_categories.empty?
            block_categories.each do |category|
              name = category.attr('name')
              script_strings['block_categories'][url][name] = name if name
            end

            ## Function Names
            functions = blocks.xpath("//block[@type=\"procedures_defnoreturn\"]")
            script_strings['function_names'][url] = Hash.new unless functions.empty?
            functions.each do |function|
              name = function.at_xpath('./title[@name="NAME"]')
              script_strings['function_names'][url][name.content] = name.content if name
            end
          end

        end
      end

      script_strings.delete_if {|_key, value| value.nil? || value.try(:empty)}

      script_i18n_directory = "../i18n/locales/source/course_content"
      if script.version_year
        script_i18n_directory = "#{script_i18n_directory}/#{script.version_year}"
      end
      Dir.mkdir script_i18n_directory unless Dir.exist? script_i18n_directory
      script_i18n_filename = "#{script_i18n_directory}/#{script.name}.yml"
      File.open(script_i18n_filename, 'w') do |file|
        file.write(to_crowdin_yaml({"en" => {"data" => script_strings}}))
      end
    end
  end

  i18n_warning = "# Autogenerated English-language level-definition locale file. Do not edit by hand or commit to version control.\n"
  File.write(yml_file, i18n_warning + dsl_i18n_strings.deep_sort.to_yaml(line_width: -1))
end

# Pull in various fields for custom blocks from .json files and save them to
# blocks.en.yml.
def localize_block_content
  blocks = {}

  Dir.glob('dashboard/config/blocks/**/*.json').sort.each do |file|
    name = File.basename(file, '.*')
    config = JSON.parse(File.read(file))['config']
    blocks[name] = {
      'text' => config['blockText'],
    }

    next unless config['args']

    args_with_options = {}
    config['args'].each do |arg|
      next if !arg['options'] || arg['options'].empty?

      options = args_with_options[arg['name']] = {}
      arg['options'].each do |option_tuple|
        options[option_tuple.last] = option_tuple.first
      end
    end
    blocks[name]['options'] = args_with_options unless args_with_options.empty?
  end

  copy_to_yml('blocks', blocks)
end

def redact_level_content
  Dir.glob("i18n/locales/source/course_content/**/*.yml").each do |source|
    backup = source.sub("source", "original")
    FileUtils.mkdir_p(File.dirname(backup))
    FileUtils.cp(source, backup)
    redact(source, source)
  end
end

sync_in if __FILE__ == $0
