# Synthetic data only: made-up coders and charts with generic encounter
# summaries. No names, dates of birth, record numbers, or dates of service.
module Seeds::Queue
  # Methods, not constants: Seeds.load_all! re-`load`s this file on every reset.
  def self.coders = [
    { slug: "maya", name: "Maya Ortiz", color: "indigo" },
    { slug: "dev", name: "Dev Raman", color: "emerald" },
    { slug: "june", name: "June Park", color: "amber" },
    { slug: "sam", name: "Sam Whitlock", color: "rose" }
  ]

  def self.specialties = {
    "Cardiology" => [ "Follow-up, stable hypertension, medication adjusted", "New patient, palpitations, ECG ordered", "Post-procedure check, no complications" ],
    "Orthopedics" => [ "Knee pain after a fall, X-ray negative", "Follow-up, healing wrist fracture, cast removed", "Chronic low back pain, physical therapy referral" ],
    "Primary care" => [ "Annual wellness visit, adult, no new concerns", "Upper respiratory symptoms, supportive care", "Type 2 diabetes follow-up, A1c reviewed, refill" ],
    "Emergency" => [ "Laceration to forearm, repaired with sutures", "Chest pain, cardiac workup negative, discharged", "Ankle sprain, splinted, discharged" ],
    "Dermatology" => [ "Skin lesion removed, sent to pathology", "Eczema flare, topical therapy updated" ],
    "Pediatrics" => [ "Well-child visit, immunizations given", "Ear pain, otitis media, antibiotics started" ]
  }

  def self.chart_types = [ "Office visit", "ED encounter", "Procedure note", "Consult" ]

  def self.reset!
    random = Random.new(84)
    now = Time.current

    ChartQueue::Chart.delete_all
    ChartQueue::Coder.delete_all
    coders = self.coders.map { |attrs| ChartQueue::Coder.create!(attrs) }

    charts = Array.new(24) do |i|
      specialty, summaries = specialties.to_a[i % specialties.size]
      ChartQueue::Chart.create!(
        reference: "CHT-#{1001 + i}",
        specialty: specialty,
        chart_type: chart_types[random.rand(chart_types.size)],
        summary: summaries[random.rand(summaries.size)],
        payout_cents: 250 + (random.rand(47) * 25),
        due_at: now + (2 + random.rand(70)).hours
      )
    end

    # A couple of live claims (expiring soon, so the SLA release shows up a
    # minute or two after a reset) and a few finished charts.
    charts.last(2).each_with_index do |chart, i|
      claimed_at = now - (80 + (i * 40)).seconds
      chart.update_columns(status: "claimed", coder_id: coders[i].id, claimed_at: claimed_at,
        claim_expires_at: claimed_at + ChartQueue::Chart::CLAIM_SLA)
      ChartQueue::ReleaseExpiredClaimsJob.set(wait_until: chart.claim_expires_at + 1.second).perform_later
    end
    charts.first(3).each_with_index do |chart, i|
      chart.update_columns(status: "done", coder_id: coders[(i + 2) % coders.size].id,
        claimed_at: now - (20 + i).minutes, completed_at: now - (10 + i).minutes)
    end

    charts.size
  end
end
