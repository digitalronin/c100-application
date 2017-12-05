require 'rails_helper'

RSpec.describe C100App::OtherChildrenDecisionTree do
  let(:c100_application) { double('Object') }
  let(:step_params)      { double('Step') }
  let(:next_step)        { nil }
  let(:as)               { nil }
  let(:record)           { nil }

  let(:c100_application) { instance_double(C100Application, children: children_collection) }
  let(:children_collection) { double('children_collection', secondary: filtered_collection) }
  let(:filtered_collection) { double('filtered_collection') }

  subject {
    described_class.new(
      c100_application: c100_application,
      record: record,
      step_params: step_params,
      as: as,
      next_step: next_step
    )
  }

  it_behaves_like 'a decision tree'

  context 'when the step is `add_another_name`' do
    let(:step_params) {{'add_another_name' => 'anything'}}
    it {is_expected.to have_destination(:names, :edit)}
  end

  context 'when the step is `names_finished`' do
    let(:step_params) {{'names_finished' => 'anything'}}

    before do
      allow(filtered_collection).to receive(:pluck).with(:id).and_return([1, 2, 3])
    end

    it 'goes to edit the details of the first child' do
      expect(subject.destination).to eq(controller: :personal_details, action: :edit, id: 1)
    end
  end

  context 'when the step is `personal_details`' do
    let(:step_params) {{'personal_details' => 'anything'}}

    before do
      allow(filtered_collection).to receive(:pluck).with(:id).and_return([1, 2, 3])
    end

    context 'when there are remaining children' do
      let(:record) { double('Child', id: 1) }

      it 'goes to edit the details of the next child' do
        expect(subject.destination).to eq(controller: :personal_details, action: :edit, id: 2)
      end
    end

    context 'when all children have been edited' do
      let(:record) { double('Child', id: 3) }
      it {is_expected.to have_destination('/steps/applicant/personal_details', :edit)}
    end
  end
end