JOB_TYPES = ["zlecenie (konkretna usługa do wykonania)", "poszukiwanie współpracowników / oferta pracy", "wolontariat (praca za reklamy, bannery, itp. lub praca za darmo)", "staż/praktyka"]
JOB_LABELS = ["zlecenie", "etat", "wolontariat", "praktyka"]
JOB_RANK_VALUES = { :price => 3, :default => 1 }

class Job < ActiveRecord::Base
	xss_terminate
	has_permalink :title
	
	validates_presence_of :title, :description, :email, :company_name, :localization_id, :framework_id
	
	#validates_length_of :framework_name, :within => 3..255, :on => :create
	#validates_presence_of :framework_name, :on => :create
	
	validates_length_of :title, :within => 3..255
	validates_length_of :description, :within => 10..5000
	validates_inclusion_of :type_id, :in => 0..JOB_TYPES.size-1
	validates_inclusion_of :dlugosc_trwania, :in => 1..60
	
	validates_numericality_of :price_from, 
			:greater_than => 0, 
			:unless => Proc.new { |j| j.price_from.nil? }
	validates_numericality_of :price_to, 
			:greater_than => 0, 
			:unless => Proc.new { |j| j.price_to.nil? }
	
	validates_format_of :email, :with => Authlogic::Regex.email
	
	validates_format_of :website, :with =>  /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
	
	validates_format_of :REGON, 
			:with => /(^$)|(^[0-9]{7,14}$)/
	validates_format_of :NIP,
			:with => /(^$)|(^\d{2,3}-\d{2,3}-\d{2,3}-\d{2,3}$)/
	validates_format_of :KRS,
			:with => /(^$)|(^\d{10})$/
	
	belongs_to :framework
	belongs_to :localization
	
	attr_protected :rank, :permalink, :end_at
	attr_accessor  :framework_name, :localization_name
	
	before_create :create_from_name
	before_save :calculate_rank
	
	def calculate_rank
		self.rank = 0
		[:REGON, :NIP, :KRS].each do |attribute|
			val = send(attribute)
			inc = JOB_RANK_VALUES[attribute] || JOB_RANK_VALUES[:default]
			self.rank += 1 unless (val.nil? || val.empty?)
		end
		
		if ((!self.price_from.nil? && self.price_from > 0) || (!self.price_to.nil? && self.price_to > 0))
			self.rank += JOB_RANK_VALUES[:price]
		end
	end
	
	def create_from_name
		unless (self.framework_name.nil? || self.framework_name.blank?) 
			framework = Framework.name_like(self.framework_name).first
			framework = Framework.create(:name => self.framework_name) if framework.nil?
			
			self.framework = framework
		end
		
		unless (self.localization_name.nil? || self.localization_name.blank?) 
			localization = Localization.name_like(self.localization_name).first
			localization = Localization.create(:name => self.localization_name) if localization.nil?
			
			self.localization = localization
		end
	end
	
	def dlugosc_trwania
		date = created_at.nil? ? Date.current.to_date : created_at.to_date
		return (read_attribute(:end_at) - date).to_i rescue 14
	end
	
	def dlugosc_trwania=(val)
		date = created_at.nil? ? Date.current.to_date : created_at.to_date
		write_attribute(:end_at, date+val.to_i.days)
	end
	
	def highlited?
		self.rank >= 6
	end
	
	def to_param
		permalink
	end
end
