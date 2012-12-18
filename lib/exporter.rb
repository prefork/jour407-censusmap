START_YEAR = 2000
END_YEAR = 2011
NUM_CLASSES = 7

class CensusExporter
  def self.run(output_directory)
    summary = Hash.new
    time = Benchmark.realtime do
      LOG('export', :blue, 'Summarizing counties...')
      summary[:county] = self.summarize_by_county

      LOG('export', :blue, 'Summarizing states...')
      summary[:state] = self.summarize_by_state

      LOG('export', :blue, 'Summarizing US...')
      summary[:us] = self.summarize_country

      LOG('export', :blue, 'Computing stats...')
      summary[:stats] = self.compute_stats(summary[:county])

      LOG('export', :blue, 'Computing indexes...')
      index = self.compute_indexes
      trie = self.compute_trie(index)

      LOG('export', :blue, 'Writing indexes...')
      self.write(index.to_json, 'index.json', output_directory)
      self.write(trie.to_json, 'trie.json', output_directory)

      LOG('export', :blue, 'Writing summaries...')
      self.write(summary.to_json, 'population_summary.json', output_directory)
    end
    LOG('export', :blue, "Completed in #{time}s")
    LOG('export', :blue, 'Success!', :green)
  end

  private

  def self.summarize_by_county
    county_summary = Hash.new
    Estimate.all.each do |e|
      unless(county_summary[e.fips_id])
        county_summary[e.fips_id] = {:county_name => e.county_name, :state_name => e.state.name, :population => {}}
      end
      county_summary[e.fips_id][:population][e.year] = e.population
    end
    return county_summary
  end

  def self.summarize_by_state
    state_summary = Hash.new
    State.all.each do |s|
      state_summary[s.name] = Hash.new
      (2000..2011).each do |year|
        state_summary[s.name][year.to_s] = Estimate.all(:state => s, :year => year.to_s).sum(:population)
      end
    end
    return state_summary
  end

  def self.summarize_country
    us_summary = Hash.new
    (2000..2011).each do |year|
      us_summary[year.to_s] = Estimate.all(:year => year.to_s).sum(:population)
    end
    return us_summary
  end

  def self.compute_stats(summary)
    output = Hash.new
    (START_YEAR..END_YEAR).each do |first|
      (START_YEAR..END_YEAR).each do |last|
        if(last > first)
          output[first.to_s] ||= Hash.new # lazy
          output[first.to_s][last.to_s] = Hash.new
          tmp = Array.new
          summary.values.each do |cty|
            tmp.push((cty[:population][last.to_s] - cty[:population][first.to_s]).to_f/cty[:population][first.to_s])
          end
          output[first.to_s][last.to_s][:min] = tmp.min
          output[first.to_s][last.to_s][:max] = tmp.max
        end
      end
    end
    return output
  end

  def self.compute_trie(index)
    words = index.keys
    trie = Hash.new
    words.each do |word|
      # turn 'word' into {w => {o => {r => {d => {}}}}}
      w = word.dup
      arr = Array.new
      hsh = Hash.new
      w.each_char {|c| arr.push(c)}
      while arr.first do
        hsh = {arr.pop => hsh}
      end
      trie.deep_merge!(hsh)
    end
    return trie
  end

  def self.compute_indexes
    words = Hash.new
    Estimate.all.each do |est|
      est.county_name.encode('UTF-8', 'UTF-8', :invalid => :replace).split(" ").each do |word|
        word = word.gsub(/[^A-Za-z]/i, '').downcase.gsub('county', '')
        if(word.length > 2 && !Stopwords.is?(word))
          unless(words[word])
            words[word] = Array.new
          end
          unless(words[word].include? est.fips_id)
            words[word].push(est.fips_id)
          end
        end
      end
    end
    return words
  end


  def self.write(contents, file_name, output_directory)
    File.open(File.join(output_directory, file_name), 'w') { |f|
      f.write(contents)
    }
  end

end
