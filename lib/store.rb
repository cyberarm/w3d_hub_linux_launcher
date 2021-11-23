class W3DHub
  class Store
    @@store = {}

    def self.get(*args)
      @@store.get(*args)
    end

    def self.[]=(key, value)
      @@store[key] = value
    end

    def self.[](key)
      @@store[key]
    end

    def self.method_missing(sym, *args)
      if args.size == 1
        self[:"#{sym.to_s.sub('=', '')}"] = args.first
      elsif args.size.zero?
        self[sym]
      else
        raise "Only one argument suppported"
      end
    end
  end
end
