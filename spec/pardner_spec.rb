require 'spec_helper'

RSpec.describe Pardner::Base do
  let!(:balloon_class) do
    balloon_class = Class.new ActiveRecord::Base
    stub_const 'Balloon', balloon_class
  end

  let!(:decorator_class) do
    decorator = Class.new(described_class) do
      howdy_pardner Balloon
    end
    stub_const 'BalloonDecorator', decorator
  end

  let(:balloon) { Balloon.new color: 'blue', size: 'large' }
  subject { BalloonDecorator.new balloon }

  describe 'delegation' do
    it 'delegates methods to decorated_record' do
      expect(subject.color).to eq 'blue'
      expect(subject.size).to eq 'large'
    end
  end

  describe 'method override' do
    it 'is allowed' do
      class << subject
        def color
          'orange'
        end
      end
      expect(subject.color).to eq 'orange'
    end

    it 'can use super to call decorated class method' do
      class << subject
        def color
          "pastel-#{super}"
        end
      end
      expect(subject.color).to eq 'pastel-blue'
    end
  end

  describe '#valid?' do
    its(:valid?) { is_expected.to eq true }

    context 'when decorator is invalid' do
      before do
        BalloonDecorator.class_eval do
          validate { errors.add :color, 'is too dark' }
        end
      end

      its(:valid?) { is_expected.to eq false }
      it 'has an error' do
        subject.valid?
        expect(subject.errors[:color]).to eq ['is too dark']
      end
    end

    context 'when decorated_record is invalid' do
      before do
        Balloon.class_eval do
          validate { errors.add :color, 'is too dark' }
        end
      end

      its(:valid?) { is_expected.to eq false }
      it 'has an error' do
        subject.valid?
        expect(subject.errors[:color]).to eq ['is too dark']
      end
    end

    context 'with a callback' do
      before do
        BalloonDecorator.class_eval do
          attr_accessor :callback_called
          before_validation { self.callback_called = true }
        end
      end

      it 'runs it' do
        subject.valid?
        expect(subject.callback_called).to eq true
      end

      context 'that returns false' do
        before do
          BalloonDecorator.class_eval do
            before_validation { false }
          end
        end
        its(:valid?) { is_expected.to eq false }
      end
    end
  end

  describe '#attributes=' do
    it 'calls decorated assignment methods' do
      class << subject
        attr_reader :called

        def color=(val)
          @called = true
          super
        end
      end

      subject.attributes = { color: 'green' }
      expect(subject.called).to eq true
      expect(subject.color).to eq 'green'
    end
  end

  describe '#[]' do
    it 'calls decorated method' do
      class << subject
        attr_reader :called

        def color
          @called = true
          super
        end
      end

      expect(subject['color']).to eq 'blue'
      expect(subject.called).to eq true
    end
  end

  describe '#[]=' do
    it 'calls decorated method' do
      class << subject
        attr_reader :called

        def color=(val)
          @called = true
          super
        end
      end

      expect(subject.color = 'green').to eq 'green'
      expect(subject.color).to eq 'green'
      expect(subject.called).to eq true
    end
  end

  describe '#save', :db do
    context 'when successful' do
      before { allow(balloon).to receive(:save).and_return true }

      its(:save) { is_expected.to eq true }

      it 'saves balloon' do
        expect(balloon).to receive(:save).and_return true
        subject.save
      end
    end

    context 'when decorator invalid' do
      before { allow(subject).to receive(:valid?).and_return false }

      its(:save) { is_expected.to eq false }

      it 'does not save balloon' do
        expect(balloon).to_not receive(:save)
        subject.save
      end
    end

    context 'when decorated record invalid' do
      before { allow(balloon).to receive(:valid?).and_return false }

      its(:save) { is_expected.to eq false }

      it 'does not save balloon' do
        expect(balloon).to_not receive(:save)
        subject.save
      end
    end

    context 'with a before callback' do
      before do
        BalloonDecorator.class_eval do
          attr_accessor :callback_called
          before_save { self.callback_called = true }
        end
      end

      it 'runs it' do
        subject.save
        expect(subject.callback_called).to eq true
      end

      context 'that returns false' do
        before do
          BalloonDecorator.class_eval do
            before_save { false }
          end
        end
        its(:save) { is_expected.to eq false }

        it 'does not save balloon' do
          expect(balloon).to_not receive(:save)
          subject.save
        end
      end
    end

    context 'with an after callback' do
      before do
        BalloonDecorator.class_eval do
          after_save { fail 'blah' }
        end
      end

      it 'rolls back transaction' do
        expect { subject.save rescue nil }.to_not change(Balloon, :count)
      end
    end

    context 'when decorated record does not return true' do
      before do
        BalloonDecorator.class_eval do
          before_save { Balloon.create! }
        end

        Balloon.class_eval do
          def save; false; end
        end
      end

      it "rolls back the transaction" do
        expect { subject.save }.to_not change(Balloon, :count)
      end
    end
  end

  context '#modal_name' do
    it 'delegates to decorated record' do
      expect(subject.model_name.to_s).to eq 'Balloon'
    end
  end

  context '.modal_name' do
    it 'delegates configured class' do
      expect(BalloonDecorator.model_name.to_s).to eq 'Balloon'
    end

    context 'without config' do
      let!(:unconfigured_class) do
        klass = Class.new described_class
        stub_const 'UnconfiguredClass', klass
      end
      it 'doesnt crash' do
        expect{UnconfiguredClass.model_name}.to_not raise_error
      end
    end
  end

  describe '#destroy', :db do
    it 'destroys the balloon' do
      expect(balloon).to receive(:destroy)
      subject.destroy
    end

    context 'with a before callback' do
      before do
        BalloonDecorator.class_eval do
          attr_accessor :callback_called
          before_destroy { self.callback_called = true }
        end
      end

      it 'runs it' do
        subject.destroy
        expect(subject.callback_called).to eq true
      end

      context 'that returns false' do
        before do
          BalloonDecorator.class_eval do
            before_destroy { false }
          end
        end

        its(:destroy) { is_expected.to eq false }

        it 'doesnt destroy the balloon' do
          expect(balloon).to_not receive(:destroy)
          subject.destroy
        end
      end
    end

    context 'with an after callback' do
      before do
        BalloonDecorator.class_eval do
          after_destroy { fail 'oops' }
        end
      end

      it 'rolls back transaction' do
        subject.save!
        expect { subject.destroy rescue nil }.to_not change(Balloon, :count)
      end
    end
  end

  describe '#update' do
    context 'when successful' do
      before { allow(balloon).to receive(:save).and_return true }

      it 'assigns attributes' do
        subject.update color: 'green'
        expect(subject.color).to eq 'green'
      end

      it 'returns true' do
        expect(subject.update(color: 'green')).to eq true
      end
    end

    context 'when unsuccessful' do
      before { allow(balloon).to receive(:save).and_return false }

      it 'assigns attributes' do
        subject.update color: 'green'
        expect(subject.color).to eq 'green'
      end

      it 'returns false' do
        expect(subject.update(color: 'green')).to eq false
      end
    end
  end

  describe '#update!' do
    context 'when successful' do
      before { allow(balloon).to receive(:save).and_return true }

      it 'assigns attributes' do
        subject.update color: 'green'
        expect(subject.color).to eq 'green'
      end

      it 'returns true' do
        expect(subject.update(color: 'green')).to eq true
      end
    end

    context 'when unsuccessful' do
      before { allow(balloon).to receive(:save).and_return false }

      it 'raises error' do
        expect { subject.update!(color: 'green') }.to raise_error(Pardner::InvalidModel)
      end
    end
  end

  describe "#persisted?" do
    context "when decorated record is persisted" do
      before { allow(balloon).to receive_messages persisted?: true, new_record?: false }
      it { is_expected.to be_persisted }
      it { is_expected.to_not be_new_record }
    end
    context "when decorated record is not persisted" do
      before { allow(balloon).to receive_messages persisted?: false, new_record?: true }
      it { is_expected.to_not be_persisted }
      it { is_expected.to be_new_record }
    end
  end

  describe '.howdy_pardner' do
    let(:parent_klass) { Class.new Pardner::Base }
    let(:child_klass) { Class.new parent_klass }

    context 'when parent class has config' do
      before do
        parent_klass.class_eval do
          howdy_pardner Balloon
        end
      end

      it 'inherits it for child' do
        expect(child_klass.pardner_config.decorated_class).to eq Balloon
      end

      context 'and child changes it' do
        let!(:another_class) do
          another_class = Class.new
          stub_const 'Another', another_class
        end

        before do
          child_klass.class_eval do
            howdy_pardner Another
          end
        end

        it 'changes child config' do
          expect(child_klass.pardner_config.decorated_class).to eq Another
        end

        it 'doesnt change parents config' do
          expect(parent_klass.pardner_config.decorated_class).to eq Balloon
        end
      end
    end
  end

  describe "#decorated_record" do
    its(:decorated_record) { is_expected.to eq balloon }
  end

  describe "#decorated_record_deep" do
    let(:layer1) { BalloonDecorator.new balloon }
    let(:layer2) { BalloonDecorator.new layer1 }
    subject { BalloonDecorator.new layer2 }
    its(:decorated_record_deep) { is_expected.to eq balloon }
  end
end
