require 'test_helper'

class Pandora::Transport::Transport::SerializerTest < Test::Unit::TestCase

  context "Serializer" do

    should "use MultiJson by default" do
      ::MultiJson.expects(:load)
      ::MultiJson.expects(:dump)
      Pandora::Transport::Transport::Serializer::MultiJson.new.load('{}')
      Pandora::Transport::Transport::Serializer::MultiJson.new.dump({})
    end

  end

end
