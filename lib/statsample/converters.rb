require 'statsample/converter/spss'
module Statsample
  # Create and dumps Datasets on a database
  # 
  # == NOTE
  # 
  # Deprecated. Use Daru::DataFrame.from_sql and Daru::DataFrame#write_sql
  module Database
    class << self
      # Read a database query and returns a Dataset
      #
      # == NOTE
      # 
      # Deprecated. Use Daru::DataFrame.from_sql instead.
      def read(dbh,query)
        raise NoMethodError, "Deprecated. Use Daru::DataFrame.from_sql instead."
      end

      # Insert each case of the Dataset on the selected table
      #
      # == NOTE
      # 
      # Deprecated. Use Daru::DataFrame#write_sql instead
      def insert(ds, dbh, table)
        raise NoMethodError, "Deprecated. Use Daru::DataFrame#write_sql instead."
      end
      # Create a sql, basen on a given Dataset
      #
      # == NOTE
      # 
      # Deprecated. Use Daru::DataFrame#create_sql instead.
      def create_sql(ds,table,charset="UTF8")
        raise NoMethodError, "Deprecated. Use Daru::DataFrame#create_sql instead."
      end
    end
  end
  module Mondrian
    class << self
      def write(dataset,filename)
        File.open(filename,"wb") do |fp|
          fp.puts dataset.vectors.to_a.join("\t")
          dataset.each_row do |row|
            row2 = row.map { |v| v.nil? ? "NA" : v.to_s.gsub(/\s+/,"_") }
            fp.puts row2.join("\t")
          end
        end
      end
    end
  end

  class PlainText
    class << self
      def read(filename, fields)
        raise NoMethodError, "Deprecated. Use Daru::DataFrame.from_plaintext instead."
      end
    end
  end
    
  # This class has been DEPRECATED. Use Daru::DataFrame::from_excel 
  # Daru::DataFrame#write_excel for XLS file operations.
  class Excel
    class << self
      # Write a Excel spreadsheet based on a dataset
      # * TODO: Format nicely date values
      # 
      # == NOTE
      # 
      # Deprecated. Use Daru::DataFrame#write_csv.
      def write(dataset,filename)
        raise NoMethodError, "Deprecated. Use Daru::DataFrame#write_excel instead."
      end

      # Returns a dataset based on a xls file
      # 
      # == NOTE
      # 
      # Deprecated. Use Daru::DataFrame.from_excel instead.
      def read(filename, opts=Hash.new)
        raise NoMethodError, "Deprecated. Use Daru::DataFrame.from_excel instead."
      end
    end
  end

  module Mx
    class << self
      def write(dataset,filename,type=:covariance)
        puts "Writing MX File"
        File.open(filename,"w") do |fp|
          fp.puts "! #{filename}"
          fp.puts "! Output generated by Statsample"
          fp.puts "Data Ninput=#{dataset.fields.size} Nobservations=#{dataset.cases}"
          fp.puts "Labels " + dataset.vectors.to_a.join(" ")
          case type
            when :raw
            fp.puts "Rectangular"
            dataset.each do |row|
              out=dataset.vectors.to_a.collect do |f|
                if dataset[f].is_valid? row[f]
                  row[f]
                else
                  "."
                end
              end
              fp.puts out.join("\t")
            end
            fp.puts "End Rectangular"
          when :covariance
            fp.puts " CMatrix Full"
            cm=Statsample::Bivariate.covariance_matrix(dataset)
            d=(0...(cm.row_size)).collect {|row|
              (0...(cm.column_size)).collect{|col|
                cm[row,col].nil? ? "." : sprintf("%0.3f", cm[row,col])
              }.join(" ")
            }.join("\n")
            fp.puts d
          end
        end
      end
    end
  end
	module GGobi
		class << self
      def write(dataset,filename,opt={})
        File.open(filename,"w") {|fp|
          fp.write(self.out(dataset,opt))
        }
      end
			def out(dataset,opt={})
				require 'ostruct'
				default_opt = {:dataname => "Default", :description=>"", :missing=>"NA"}
				default_opt.merge! opt
				carrier=OpenStruct.new
				carrier.categorials=[]
				carrier.conversions={}
				variables_def=dataset.vectors.to_a.collect{|k|
					variable_definition(carrier,dataset[k],k)
				}.join("\n")

				indexes=carrier.categorials.inject({}) {|s,c|
					s[dataset.vectors.to_a.index(c)]=c
					s
				}
				records=""
				dataset.each_row {|c|
					indexes.each { |ik,iv|
						c[ik] = carrier.conversions[iv][c[ik]]
					}
					records << "<record>#{values_definition(c, default_opt[:missing])}</record>\n"
				}

out=<<EOC
<?xml version="1.0"?>
<!DOCTYPE ggobidata SYSTEM "ggobi.dtd">
<ggobidata count="1">
<data name="#{default_opt[:dataname]}">
<description>#{default_opt[:description]}</description>
<variables count="#{dataset.fields.size}">
#{variables_def}
</variables>
    <records count="#{dataset.cases}" missingValue="#{default_opt[:missing]}">
#{records}
</records>

</data>
</ggobidata>
EOC

out

			end
      def values_definition(c,missing)
        c.collect{|v|
          if v.nil?
            "#{missing}"
          elsif v.is_a? Numeric
            "#{v}"
          else
            "#{v.gsub(/\s+/,"_")}"
          end
        }.join(" ")
      end
			# Outputs a string for a variable definition
			# v = vector
			# name = name of the variable
			# nickname = nickname
			def variable_definition(carrier,v,name,nickname=nil)
				nickname = (nickname.nil? ? "" : "nickname=\"#{nickname}\"" )
				if v.type==:object or v.to_a.find {|d|  d.is_a? String }
					carrier.categorials.push(name)
					carrier.conversions[name]={}
					factors=v.factors
					out ="<categoricalvariable name=\"#{name}\" #{nickname}>\n"
					out << "<levels count=\"#{factors.size}\">\n"
					out << (1..factors.size).to_a.collect{|i|
						carrier.conversions[name][factors[i-1]]=i
						"<level value=\"#{i}\">#{(v.labels[factors[i-1]] || factors[i-1])}</level>"
					}.join("\n")
					out << "</levels>\n</categoricalvariable>\n"
					out
				elsif v.to_a.find {|d| d.is_a? Float}
					"<realvariable name=\"#{name}\" #{nickname} />"
				else
					"<integervariable name=\"#{name}\" #{nickname} />"
				end
			end
		end
	end
end

require 'statsample/converter/csv.rb'

