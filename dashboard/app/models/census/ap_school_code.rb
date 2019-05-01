# == Schema Information
#
# Table name: ap_school_codes
#
#  school_year :integer
#  school_code :string(6)        not null, primary key
#  school_id   :string(12)       not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  fk_rails_08d2269647                                   (school_id)
#  index_ap_school_codes_on_school_code_and_school_year  (school_code,school_year) UNIQUE
#

class Census::ApSchoolCode < ApplicationRecord
  self.primary_keys = :school_code, :school_year

  belongs_to :school, required: true
  has_many :ap_cs_offering, foreign_key: [:school_code, :school_year], primary_key: [:school_code, :school_year]

  validates :school_code, presence: true, length: {is: 6}, format: {with: /\A[0-9]+\z/, message: "only allows numbers"}

  validates :school_year, presence: true, numericality: {greater_than_or_equal_to: 2016, less_than_or_equal_to: 2030}

  # school_code is a 6-character string but in the input files we may have treated
  # them as integers and cut off leading zeros. Add them back if necessary.
  def self.normalize_school_code(raw_school_code)
    format("%06d", raw_school_code.to_i)
  end

  def self.seed_from_csv(filename, school_year)
    ActiveRecord::Base.transaction do
      CSV.foreach(filename, {headers: true}) do |row|
        normalized_school_code = normalize_school_code(row.to_hash['school_code'])
        begin
          school_id = School.normalize_school_id(row.to_hash['school_id'])
          school = School.find_by(id: school_id)
          if school.nil?
            puts "AP School Code seed: school not found - skipping row for school_code:#{normalized_school_code} school_id:#{school_id}"
          else
            find_or_create_by!(school_code: normalized_school_code, school: school, school_year: school_year)
          end
        end
      end
    end
  end

  CENSUS_BUCKET_NAME = "cdo-census".freeze
  CSV_OBJECT_KEY = "ap_school_codes.csv".freeze

  def self.seed_from_s3
    AWS::S3.seed_from_file(CENSUS_BUCKET_NAME, CSV_OBJECT_KEY) do |filename|
      seed_from_csv(filename)
    end
  end

  def self.seed
    if CDO.stub_school_data
      seed_from_csv("test/fixtures/census/ap_school_codes.csv", 2016)
    else
      seed_from_s3
    end
  end
end
