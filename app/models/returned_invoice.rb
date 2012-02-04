class ReturnedInvoice < ActiveRecord::Base
  # Sorting
  default_scope :order => "doctor_id, state"

  # String
  def to_s
    "%s: %s" % [state, invoice]
  end

  # State Machine
  include AASM
  aasm_column :state
  validates_presence_of :state

  aasm_initial_state :ready
  aasm_state :ready
  aasm_state :request_pending
  aasm_state :resolved

  aasm_event :queue_request do
    transitions :from => :ready, :to => :request_pending
  end

  aasm_event :resolve do
    transitions :from => [:ready, :request_pending], :to => :resolved
  end

  named_scope :open, :conditions => {:state => ['ready', 'request_pending']}

  # Invoice
  belongs_to :invoice
  validates_presence_of :invoice_id
  validates_presence_of :invoice, :message => 'Rechnung nicht gefunden'

  def patient
    # Guard
    return unless invoice

    invoice.patient
  end

  # Doctor
  belongs_to :doctor
  named_scope :by_doctor_id, lambda {|doctor_id| {:conditions => {:doctor_id => doctor_id}}}
  before_save :set_doctor
private
  def set_doctor
    self.doctor = invoice.treatment.referrer
  end
end