texts = {
  "_texts/en-imperialism-highest-stage-of-capitalism.md" => "https://www.marxists.org/archive/lenin/works/1916/imp-hsc/",
  "_texts/en-value-price-and-profit.md" => "https://www.marxists.org/archive/marx/works/1865/value-price-profit/",
  "_texts/en-the-state-and-revolution.md" => "https://www.marxists.org/archive/lenin/works/1917/staterev/",
  "_texts/en-wage-labour-and-capital.md" => "https://www.marxists.org/archive/marx/works/1847/wage-labour/"
}

texts.each do |file, url|
  next unless File.exist?(file)
  content = File.read(file)
  unless content.include?("source_url:")
    content.sub!(/^---$/, "source_url: \"#{url}\"\n---")
    File.write(file, content)
  end
end
