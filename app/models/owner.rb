class Owner < ApplicationRecord
  
    # Callbacks
    # -----------------------------
    # create a callback that will strip non-digits before saving to db
    before_save :reformat_phone
    
    # create a callback that will capitalize the last name of an owner before saving it to db
    before_save :capitalize_last_name
  
    # Relationships
    # -----------------------------
    has_many :pets # :dependent => :destroy  (:nullify option will break link, but leaves orphan records)
    has_many :visits, through: :pets
  
    # They essentially do the same thing, 
    # the only difference is what side of the relationship you are on. 
    # If a User has a Profile , then in the User class you'd have has_one :profile and 
    # in the Profile class you'd have belongs_to :user 
  
    # Scopes
    # -----------------------------
    # list owners in alphabetical order
    scope :alphabetical, -> { order('last_name, first_name') }
    # OR
    # scope :alphabetical, lambda {order('last_name, first_name')}
    # get all the owners who are active (not moved out and pet is alive)
    scope :active, -> { where(active: true) }
    #get all the owners who are inactive (have moved out or pet is dead)
    scope :inactive, -> { where.not(active: true) }
    # OR
    # scope :inactive, ->{where (active: false)}
    # search all the owners in the system having a given first name
    # term (the search query) is the parameter for the anonymous method.
    # scope :search, ->(term) { where('first_name LIKE ?', "#{term}%")}
  
    # search all the owners in the system by either first name or last name
    scope :search, ->(term) { where('first_name LIKE ? OR last_name LIKE ?', "#{term}%", "#{term}%") }
   
   # Misc Constants
    # -----------------------------
    # This is a local vet shop, but it is possible to have people coming from WV and OH as well
    # Set up a states array to make select menu easier later
    # STATES_LIST = [['Ohio', 'OH'],['Pennsylvania', 'PA'],['West Virginia', 'WV']]
    # Here is a complete states list if you want to expand the menu options...
    # STATES_LIST = [['Alabama', 'AL'],['Alaska', 'AK'],['Arizona', 'AZ'],['Arkansas', 'AR'],['California', 'CA'],['Colorado', 'CO'],['Connectict', 'CT'],['Delaware', 'DE'],['District of Columbia ', 'DC'],['Florida', 'FL'],['Georgia', 'GA'],['Hawaii', 'HI'],['Idaho', 'ID'],['Illinois', 'IL'],['Indiana', 'IN'],['Iowa', 'IA'],['Kansas', 'KS'],['Kentucky', 'KY'],['Louisiana', 'LA'],['Maine', 'ME'],['Maryland', 'MD'],['Massachusetts', 'MA'],['Michigan', 'MI'],['Minnesota', 'MN'],['Mississippi', 'MS'],['Missouri', 'MO'],['Montana', 'MT'],['Nebraska', 'NE'],['Nevada', 'NV'],['New Hampshire', 'NH'],['New Jersey', 'NJ'],['New Mexico', 'NM'],['New York', 'NY'],['North Carolina','NC'],['North Dakota', 'ND'],['Ohio', 'OH'],['Oklahoma', 'OK'],['Oregon', 'OR'],['Pennsylvania', 'PA'],['Rhode Island', 'RI'],['South Carolina', 'SC'],['South Dakota', 'SD'],['Tennessee', 'TN'],['Texas', 'TX'],['Utah', 'UT'],['Vermont', 'VT'],['Virginia', 'VA'],['Washington', 'WA'],['West Virginia', 'WV'],['Wisconsin ', 'WI'],['Wyoming', 'WY']]
    
    # Validations
    # -----------------------------
    # make sure required fields are present
    validates_presence_of :first_name, :last_name, :email, :phone
    # if zip included, it must be 5 digits only
    validates_format_of :zip, with: /\A\d{5}\z/, message: "should be five digits long", allow_blank: true
    # phone can have dashes, spaces, dots and parens, but must be 10 digits
    validates_format_of :phone, with: /\A(\d{10}|\(?\d{3}\)?[-. ]\d{3}[-.]\d{4})\z/, message: "should be 10 digits (area code needed) and delimited with dashes only"
    # email format (other regex for email exist; doesn't allow .museum, .aero, etc.)
    # Not allowing for .uk, .ca, etc. because this is a Pittsburgh business and customers not likely to be out-of-country
    validates_format_of :email, with: /\A[\w]([^@\s,;]+)@(([\w-]+\.)+(com|edu|org|net|gov|mil|biz|info))\z/i, message: "is not a valid format"    # if state is given, must be one of the choices given (no hacking this field)
    # validates_inclusion_of :state, in: %w[PA OH WV], message: "is not an option", allow_blank: true
   
    # if not limited to the three states, it might be better (but slightly slower) to write:
    # STATES_LIST = [['Alabama', 'AL'],['Alaska', 'AK'],['Arizona', 'AZ'],['Arkansas', 'AR'],['California', 'CA'],['Colorado', 'CO'],['Connectict', 'CT'],['Delaware', 'DE'],['District of Columbia ', 'DC'],['Florida', 'FL'],['Georgia', 'GA'],['Hawaii', 'HI'],['Idaho', 'ID'],['Illinois', 'IL'],['Indiana', 'IN'],['Iowa', 'IA'],['Kansas', 'KS'],['Kentucky', 'KY'],['Louisiana', 'LA'],['Maine', 'ME'],['Maryland', 'MD'],['Massachusetts', 'MA'],['Michigan', 'MI'],['Minnesota', 'MN'],['Mississippi', 'MS'],['Missouri', 'MO'],['Montana', 'MT'],['Nebraska', 'NE'],['Nevada', 'NV'],['New Hampshire', 'NH'],['New Jersey', 'NJ'],['New Mexico', 'NM'],['New York', 'NY'],['North Carolina','NC'],['North Dakota', 'ND'],['Ohio', 'OH'],['Oklahoma', 'OK'],['Oregon', 'OR'],['Pennsylvania', 'PA'],['Rhode Island', 'RI'],['South Carolina', 'SC'],['South Dakota', 'SD'],['Tennessee', 'TN'],['Texas', 'TX'],['Utah', 'UT'],['Vermont', 'VT'],['Virginia', 'VA'],['Washington', 'WA'],['West Virginia', 'WV'],['Wisconsin ', 'WI'],['Wyoming', 'WY']]
    # validates_inclusion_of :state, in: STATES_LIST.map {|key, value| value}, message: "is not an option", allow_blank: true
  
    validates_inclusion_of :state, in: %w[PA OH WV], message: "is not an option", allow_blank: true

    # Other methods
    # -------------
    # a method to get one owner's (an object of type owner) name in last, first format
    def name
      last_name + ", " + first_name
    end
    
    # a method to get owner name in first, last format
    def proper_name
      first_name + " " + last_name
    end
  
    # a method to make an Owner inactive
    def make_inactive
      self.active=false
      self.save!
    end
  
    # a method to make an Owner active
    def make_active
      self.active=true
      self.save!
    end
  
    # Private methods for custom validations and callback handlers
    # -----------------------------
    private
    # We need to strip non-digits before saving to db
  
    # phone must be present and a 10 digit number, but the user may input values with
    # dashes, dots or other common formats – e.g., 999-999-9999; 999.999.9999; (999)
    # 999-9999 are all acceptable
  
    def reformat_phone
      phone = self.phone.to_s  # change to string in case input as all numbers 
      phone=phone.gsub(/[^0-9]/,"") # strip all non-digits: it substitutes all digits with empty character
      self.phone = phone       # reset self.phone to new string
    end

    def capitalize_last_name
      # "destructive" methods are methods that modify the object they are called on. 
      # These methods typically end with an exclamation mark (!) to indicate
      #  that they are potentially dangerous or non-idempotent, 
      # meaning they can alter the original object irreversibly.
      self.last_name.capitalize! #this is what we call a destructive method
      # equivalent to
      # self.last_name= self.last_name.capitalize
    end


end
















