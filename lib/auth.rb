module Rim
  class Auth
    Mechanisms = ['PLAIN', 'DIGEST-MD5']
    Namespace = 'urn:ietf:params:xml:ns:xmpp-sasl'
    
    attr_accessor :mechanism, :nonce, :done, :user, :namespace
    def h(s)
      Digest::MD5.digest(s)
    end
  
    def hh(s)
      Digest::MD5.hexdigest(s)
    end
    
    def initialize
      self.namespace = Rim::Auth::Namespace
    end
    
    def features
      mech = REXML::Element.new('mechanisms')
      mech.add_namespace(self.namespace)
      
      Rim::Auth::Mechanisms.each do |con_type|
        mechxml = REXML::Element.new('mechanism')
        mechxml.text = con_type
        mech << mechxml
      end
      
      mech
    end
    
    def success
      success = REXML::Element.new("success")
      success.add_namespace(self.namespace)
      success
    end
    
    def support?(mechanism)
      Rim::Auth::Mechanisms.include?(mechanism)
    end
    
    def use(new_mechanism)
      mechanism = mechanism
    end
    
    def realm
      "localhost" #TODO Move this to config file
    end
    
    def prepare_chellange
      chellange = REXML::Element.new('challenge')
      chellange.add_namespace(self.namespace)
      
      self.nonce = ((Time.new.to_f * 10000)*rand).to_i.to_s(32)
      output = "realm=#{self.realm.inspect},nonce=#{self.nonce},qop=\"auth\",charset=utf-8,algorithm=md5-sess"
      
      chellange.text = Base64.encode64(output)
      chellange
    end
    
    def response_value(username, realm, digest_uri, passwd, nonce, cnonce, qop, authzid)
      a1_h = h("#{username}:#{realm}:#{passwd}")
      a1 = "#{a1_h}:#{nonce}:#{cnonce}"
      if authzid
        a1 += ":#{authzid}"
      end
      if qop == 'auth-int' || qop == 'auth-conf'
        a2 = "AUTHENTICATE:#{digest_uri}:00000000000000000000000000000000"
      else
        a2 = "AUTHENTICATE:#{digest_uri}"
      end
      [hh("#{hh(a1)}:#{nonce}:00000001:#{cnonce}:#{qop}:#{hh(a2)}"), a1]
    end
    
    def parse_response(stream)
      node = stream.node
      unless node.text.empty?
        re = /((?:[\w-]+)\s*=\s*(?:(?:"[^"]+")|(?:[^,]+)))/
        response = {}
        Base64.decode64(node.text).scan(re) do |kv|
          k, v = kv[0].split('=', 2)
          v.gsub!(/^"(.*)"$/, '\1')
          response[k] = v
        end
        
        #Rim.logger.debug response.inspect
        
        node   = response['username'].downcase
        domain = response['realm'].downcase
        @jid   = node + '@' + domain
        
        Rim.logger.info "Searching for user in db: #{node}"
        self.user = User.where(login: node).first
        
        if self.user.nil?
          raise FailureException.not_authorized(self.namespace)
        end
        
        password = self.user.password
        
        myresp, a1 = response_value(node, domain, response['digest-uri'], password, response['nonce'], response['cnonce'], response['qop'], response['authzid'])
        
        unless myresp == response['response']
          Rim.logger.info "Not authorized: #{myresp} != #{response['response']}"
          raise FailureException.not_authorized(self.namespace)
        else
          Rim.logger.info "Authorized: #{@jid}"
          a2 = ":%s" % response['digest-uri']
          rspauth = "%s:%s:%s:%s:auth:%s" % [hh(a1), response['nonce'], response['nc'], response['cnonce'], hh(a2)]
      
          rspauth = "rspauth=%s" % hh(rspauth)
          rspauth = Base64.encode64(rspauth)
          rspauth.gsub!("\n", '')
      
          chal = REXML::Element.new('challenge')
          chal.add_namespace(self.namespace)
          chal.text = rspauth
          
          stream.write chal
          done = true
        end
        
      end
      
      
    end
  end
  
end