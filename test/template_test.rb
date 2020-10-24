# frozen_string_literal: true

require 'minitest/autorun'

class TemplateTest < Minitest::Test
  def setup
    system('[ -d test_api_app ] && rm -rf test_api_app')
  end

  def teardown
    setup
  end

  def test_generator_succeeds
    output, _err = capture_subprocess_io do
      system('DISABLE_SPRING=1 INTERACTIVE=false rails new -m template.rb test_api_app --api')
    end
    assert_match(/Application generated successfully/, output)
  end
end
