require 'action_controller' # for HTML. Note that HTML was removed in rails 4.2

class ResponseDecorator

  def initialize(app)
    @app = app
  end

  def call(env)
    dup._call(env)
  end

  def _call(env)
    @start = Time.now
    @status, @headers, @response = @app.call(env)
    if @status == 200 && @headers.is_a?(Hash) && @headers['Content-Type'].to_s.start_with?('text/html')
      append_response do |text|
        text << "<!-- script tag goes here -->\n"
      end
    end
    @stop = Time.now
    [@status, @headers, self]
  end

  def each(&block)
    @response.each(&block)
  end

  private
  def append_response(&block)
    #TODO see what performs better for finding the head tag
    # for small response bodies, a regex might be faster
    # for huge html files, a sax parser (like nokogiri) might be a better choise
    raw_body = @response.body
    tokens = HTML::Tokenizer.new(raw_body)
    pos = 0
    while token = tokens.next
      pos += token.size
      node = HTML::Node.parse(nil, 0, 0, token, false)
      if node.is_a?(HTML::Tag) && node.name == 'head'
        break;
      end
    end

    if pos < raw_body.size
      body = raw_body[0..pos]
      yield body
      body << raw_body[pos..-1]
      @response.body = body
    end

  end
end