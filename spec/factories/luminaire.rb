FactoryGirl.define do
  factory :luminaire do
    sequence :ctn do |n|
      "16253931#{n}"
    end
    sequence :itemnr do |n|
      "91500412280#{n}"
    end
  end
end
