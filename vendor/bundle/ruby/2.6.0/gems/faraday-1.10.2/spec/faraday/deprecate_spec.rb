# frozen_string_literal: true

RSpec.describe Faraday::DeprecatedClass do
  class SampleClass < StandardError
    attr_accessor :foo

    def initialize(foo = nil)
      @foo = foo || :foo
    end
  end

  SampleDeprecatedClass = Faraday::DeprecatedClass.proxy_class(SampleClass)

  it 'does not raise error for deprecated classes but prints an error message' do
    error_message, foobar = with_warn_squelching { SampleDeprecatedClass.new(:foo_bar) }
    expect(foobar).to be_a(SampleClass)
    expect(foobar.foo).to eq(:foo_bar)
    expect(error_message).to match(
      Regexp.new(
        'NOTE: SampleDeprecatedClass.new is deprecated; '\
        'use SampleClass.new instead. It will be removed in or after version 1.0'
      )
    )
  end

  it 'does not raise an error for inherited error-namespaced classes but prints an error message' do
    error_message, = with_warn_squelching { Class.new(SampleDeprecatedClass) }

    expect(error_message).to match(
      Regexp.new(
        'NOTE: Inheriting SampleDeprecatedClass is deprecated; '\
        'use SampleClass instead. It will be removed in or after version 1.0'
      )
    )
  end

  it 'allows backward-compatible class to be subclassed' do
    expect do
      with_warn_squelching { Class.new(SampleDeprecatedClass) }
    end.not_to raise_error
  end

  it 'allows rescuing of a current error with a deprecated error' do
    expect { raise SampleClass, nil }.to raise_error(SampleDeprecatedClass)
  end

  it 'allows rescuing of a current error with a current error' do
    expect { raise SampleClass, nil }.to raise_error(SampleClass)
  end

  it 'allows rescuing of a deprecated error with a deprecated error' do
    expect { raise SampleDeprecatedClass, nil }.to raise_error(SampleDeprecatedClass)
  end

  it 'allows rescuing of a deprecated error with a current error' do
    expect { raise SampleDeprecatedClass, nil }.to raise_error(SampleClass)
  end

  describe 'match behavior' do
    class SampleDeprecatedClassA < SampleDeprecatedClass; end
    class SampleDeprecatedClassB < SampleDeprecatedClass; end

    class SampleDeprecatedClassAX < SampleDeprecatedClassA; end

    class SampleClassA < SampleClass; end

    describe 'undeprecated class' do
      it 'is === to instance of deprecated class' do
        expect(SampleDeprecatedClass.new.is_a?(SampleClass)).to be true
      end

      it 'is === to instance of subclass of deprecated class' do
        expect(SampleDeprecatedClassA.new.is_a?(SampleClass)).to be true
      end

      it 'is === to instance of subclass of subclass of deprecated class' do
        expect(SampleDeprecatedClassAX.new.is_a?(SampleClass)).to be true
      end
    end

    describe 'subclass of undeprecated class' do
      it 'is not === to instance of undeprecated class' do
        expect(SampleClass.new.is_a?(SampleClassA)).to be false
      end

      it 'is not === to instance of deprecated class' do
        expect(SampleDeprecatedClass.new.is_a?(SampleClassA)).to be false
      end
    end

    describe 'deprecated class' do
      it 'is === to instance of undeprecated class' do
        expect(SampleDeprecatedClass.new.is_a?(SampleClass)).to be true
      end

      it 'is === to instance of subclass of undeprecated class' do
        expect(SampleClassA.superclass == SampleDeprecatedClass.superclass).to be true
      end

      it 'is === to instance of subclass of deprecated class' do
        expect(SampleDeprecatedClassA.new.is_a?(SampleDeprecatedClass)).to be true
      end

      it 'is === to instance of subclass of subclass of deprecated class' do
        expect(SampleDeprecatedClassAX.new.is_a?(SampleDeprecatedClass)).to be true
      end
    end

    describe 'subclass of deprecated class' do
      it 'is not === to instance of subclass of undeprecated class' do
        expect(SampleClass.new.is_a?(SampleDeprecatedClassA)).to be false
      end

      it 'is not === to instance of another subclass of deprecated class' do
        expect(SampleDeprecatedClassB.new.is_a?(SampleDeprecatedClassA)).to be false
      end

      it 'is === to instance of its subclass' do
        expect(SampleDeprecatedClassAX.new.is_a?(SampleDeprecatedClassA)).to be true
      end

      it 'is === to instance of deprecated class' do
        expect(SampleDeprecatedClassB.new.is_a?(SampleDeprecatedClass)).to be true
      end
    end

    describe 'subclass of subclass of deprecated class' do
      it 'is not === to instance of subclass of another subclass of deprecated class' do
        expect(SampleDeprecatedClassB.new.is_a?(SampleDeprecatedClassAX)).to be false
      end

      it 'is not === to instance of its superclass' do
        expect(SampleDeprecatedClass.new.is_a?(SampleDeprecatedClassA)).to be false
      end
    end
  end

  def with_warn_squelching
    stderr_catcher = StringIO.new
    original_stderr = $stderr
    $stderr = stderr_catcher
    result = yield if block_given?
    [stderr_catcher.tap(&:rewind).string, result]
  ensure
    $stderr = original_stderr
  end
end
