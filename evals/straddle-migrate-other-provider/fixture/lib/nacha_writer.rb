# Builds a NACHA file for the day's tuition debits.
class NachaWriter
  def initialize(entries)
    @entries = entries
  end

  def to_s
    lines = ["101 091000019 1234567890#{Time.now.strftime('%y%m%d%H%M')}A094101BANK OF EXAMPLE        ACADEMY INC"]
    @entries.each_with_index do |entry, i|
      lines << format("627%<routing>s%<account>-17s%<amount>010d%<id>-15s%<name>-22s  0%<trace>015d",
                      routing: entry[:routing], account: entry[:account], amount: entry[:amount_cents],
                      id: entry[:id], name: entry[:name], trace: i + 1)
    end
    lines.join("\n")
  end
end
