class User
  include Mongoid::Document
  field :provider, :type => String
  field :uid, :type => String
  field :name, :type => String
  field :email, :type => String
  field :pid, :type => Integer
  field :token, :type => String
  field :secret, :type => String
  attr_accessible :provider, :uid, :name, :email

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      user.token = auth['credentials']['token']
      user.secret = auth['credentials']['secret']
      if auth['info']
        user.name = auth['info']['name'] if auth['info']['name']
      end
    end
  end

  def tweets
    tweets ||= db.collection("tweets_#{self.uid}")
  end
end