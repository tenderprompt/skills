#!/usr/bin/env ruby

require "json"
require "pathname"
require "yaml"

ROOT = Pathname.new(__dir__).join("..").expand_path
MANIFEST_PATHS = [
  ROOT.join(".claude-plugin/plugin.json"),
  ROOT.join(".codex-plugin/plugin.json")
].freeze
CANONICAL_SKILLS_PATH = "./skills/"

def fail_validation(message)
  warn "validation failed: #{message}"
  exit 1
end

def load_json(path)
  JSON.parse(path.read)
rescue JSON::ParserError => error
  fail_validation("#{path.relative_path_from(ROOT)} is invalid JSON: #{error.message}")
end

def load_yaml(path, content = path.read)
  YAML.safe_load(content, permitted_classes: [], permitted_symbols: [], aliases: false)
rescue Psych::SyntaxError => error
  fail_validation("#{path.relative_path_from(ROOT)} is invalid YAML: #{error.message}")
end

def skill_frontmatter(path)
  content = path.read
  match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
  fail_validation("#{path.relative_path_from(ROOT)} is missing YAML frontmatter") unless match

  frontmatter = load_yaml(path, match[1])
  fail_validation("#{path.relative_path_from(ROOT)} frontmatter must be a mapping") unless frontmatter.is_a?(Hash)

  frontmatter
end

manifests = MANIFEST_PATHS.to_h do |path|
  fail_validation("missing #{path.relative_path_from(ROOT)}") unless path.file?
  [path, load_json(path)]
end

manifests.each do |path, manifest|
  relative_path = path.relative_path_from(ROOT)
  %w[name version description author skills].each do |field|
    fail_validation("#{relative_path} is missing #{field}") unless manifest.key?(field)
  end
  fail_validation("#{relative_path} author.name is required") unless manifest.dig("author", "name").is_a?(String)
  fail_validation("#{relative_path} must reference #{CANONICAL_SKILLS_PATH}") unless manifest["skills"] == CANONICAL_SKILLS_PATH

  skills_path = ROOT.join(manifest["skills"]).cleanpath
  fail_validation("#{relative_path} skills path escapes the repository") unless skills_path.to_s.start_with?("#{ROOT}/")
  fail_validation("#{relative_path} skills path does not exist") unless skills_path.directory?
end

skill_paths = ROOT.glob("skills/*/SKILL.md").sort
fail_validation("no canonical skills found under skills/") if skill_paths.empty?

skill_versions = skill_paths.to_h do |path|
  frontmatter = skill_frontmatter(path)
  %w[name description].each do |field|
    fail_validation("#{path.relative_path_from(ROOT)} frontmatter is missing #{field}") unless frontmatter[field].is_a?(String)
  end

  version = frontmatter.dig("metadata", "version")
  fail_validation("#{path.relative_path_from(ROOT)} metadata.version is required") unless version.is_a?(String)
  [path, version]
end

skill_versions.each do |path, version|
  manifests.each do |manifest_path, manifest|
    next if manifest["version"] == version

    fail_validation(
      "#{manifest_path.relative_path_from(ROOT)} version #{manifest["version"]} " \
      "does not match #{path.relative_path_from(ROOT)} version #{version}"
    )
  end
end

ROOT.glob("skills/**/*.yaml").sort.each do |path|
  data = load_yaml(path)
  fail_validation("#{path.relative_path_from(ROOT)} must contain a YAML mapping") unless data.is_a?(Hash)
end

codex_interface = manifests.fetch(ROOT.join(".codex-plugin/plugin.json"))["interface"]
fail_validation(".codex-plugin/plugin.json interface must be a mapping") unless codex_interface.is_a?(Hash)
%w[displayName shortDescription longDescription developerName category capabilities websiteURL defaultPrompt].each do |field|
  fail_validation(".codex-plugin/plugin.json interface is missing #{field}") unless codex_interface.key?(field)
end

default_prompts = codex_interface["defaultPrompt"]
fail_validation("Codex defaultPrompt must contain one to three prompts") unless default_prompts.is_a?(Array) && (1..3).cover?(default_prompts.length)
default_prompts.each do |prompt|
  fail_validation("Codex defaultPrompt entries must be strings no longer than 128 characters") unless prompt.is_a?(String) && prompt.length <= 128
end

readme = ROOT.join("README.md").read
[
  /claude plugin install\s+tender/i,
  /codex plugin add\s+tender/i
].each do |pattern|
  fail_validation("README contains an unverified public marketplace install command") if readme.match?(pattern)
end

invalid_product_names = ["Tender Generated App"]
repository_text = ROOT.glob("{README.md,skills/**/*.md,.claude-plugin/*.json,.codex-plugin/*.json}")
  .map(&:read)
  .join("\n")
invalid_product_names.each do |name|
  fail_validation("repository uses invalid product name #{name.inspect}") if repository_text.include?(name)
end

puts "Validated #{skill_paths.length} canonical skill, #{MANIFEST_PATHS.length} provider manifests, and bundled YAML metadata."
