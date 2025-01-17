require 'test_helper'

class Pd::FitWeekendRegistrationBaseTest < ActiveSupport::TestCase
  test 'required field validations' do
    registration = build(:pd_fit_weekend1920_registration, form_data: nil)
    refute registration.valid?
    assert_equal [
      "Form data is required",
    ], registration.errors.full_messages

    registration.form_data = {}.to_json
    refute registration.valid?
    assert_equal [
      "Form data preferredFirstName",
      "Form data lastName",
      "Form data email",
      "Form data phone",
      "Form data ableToAttend",
      "Form data contactFirstName",
      "Form data contactLastName",
      "Form data contactRelationship",
      "Form data contactPhone",
      "Form data dietaryNeeds",
      "Form data liveFarAway",
      "Form data howTraveling",
      "Form data needHotel",
      "Form data needDisabilitySupport",
      "Form data liabilityWaiver",
      "Form data agreeShareContact",
    ], registration.errors.full_messages

    registration.form_data = build(:pd_fit_weekend1920_registration_hash).to_json

    assert registration.valid?
  end

  test 'declined application requires fewer fields' do
    registration = create(:pd_fit_weekend1920_registration, status: :declined)

    assert registration.valid?
    refute registration.sanitize_form_data_hash.key?(:contact_first_name)
    refute registration.sanitize_form_data_hash.key?(:dietary_needs)
  end
end
