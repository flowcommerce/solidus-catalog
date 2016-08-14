module Util

  def Util.read_key(path)
    if !File.exists?(path)
      puts "ERROR: Could not read keyfile. Expected at #{path}"
      exit(1)
    end

    IO.readlines(path).each do |l|
      name, value = l.strip.split(":", 2).map(&:strip)
      if name.to_s.downcase == "solidus api key"
        return value
      end
    end
    raise "Key not found"
  end

end

