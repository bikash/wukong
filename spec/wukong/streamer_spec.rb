require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe :streamers, :helpers => true do
  describe Wukong::Streamer do
    context 'registry' do
      it 'contains standard streamers' do
        [:identity, :counter, :limit].each do |handle|
          klass = "Wukong::Streamer::#{handle.to_s.camelize}".constantize
          Wukong::Stage.klass_for(:streamer, handle).should == klass
        end
      end
    end
  end
  describe Wukong::Streamer::Base do
    context "has stub methods so everything can call super" do
      it{ should respond_to(:call) }
      it{ should respond_to(:emit) }
      it{ should respond_to(:finally) }
      it{ should respond_to(:reset!) }
    end

    context "#initialize" do
      it 'calls reset!' do
        described_class.any_instance.should_receive(:reset!)
        described_class.new
      end
    end
  end

  describe Wukong::Streamer::Identity do
    it 'outputs every record, unmodified' do
      subject.should_receive(:emit).with(mock_record)
      subject.call(mock_record)
    end
  end

  describe Wukong::Streamer::Counter do
    context "when first created" do
      its(:count){ should eq(0) }
    end

    context "#reset" do
      it 'sets the count to 0' do
        3.times{ subject.call("hi") }
        subject.count.should eq(3)
        subject.reset!
        subject.count.should eq(0)
      end
    end
  end

  describe Wukong::Streamer::Map do
    let(:test_proc){ ->(rec){ emit(rec.reverse) } }
    subject{ described_class.new( test_proc ) }

    it 'emits the output of the proc' do
      subject.should_receive(:emit).with("won ytineres")
      subject.call("serenity now")
    end
  end

  describe Wukong::Streamer::Group do

    it 'works in an example flow flow' do
      test_sink = test_array_sink
      Wukong.flow(:simple) do
        source(:iter, [1,1,1,2,2,3,5,5] )     |
          group                               |
          map{|rec| emit [rec.first, rec.length] } |
          test_sink
        run
      end
      test_sink.records.should == [ [1,3], [2,2], [3,1], [5,2] ]
    end

    # it 'calls end_group at the end'
    # 
    # it 'on an empty stream'
    
  end

end