module Trello
  # A Member is a user of the Trello service.
  class Member < BasicData
    register_attributes :id, :username, :full_name, :avatar_id, :bio, :url, :readonly => [ :id, :username, :avatar_id, :url ]
    validates_presence_of :id, :username
    validates_length_of   :full_name, :minimum => 4
    validates_length_of   :bio,       :maximum => 16384

    include HasActions

    class << self
      # Finds a user
      #
      # The argument may be specified as either an _id_ or a _username_.
      def find(id_or_username)
        super(:members, id_or_username)
      end
    end

    # Update the fields of a member.
    #
    # Supply a hash of string keyed data retrieved from the Trello API representing
    # an Member.
    def update_fields(fields)
      attributes[:id]        = fields['id']
      attributes[:full_name] = fields['fullName']
      attributes[:username]  = fields['username']
      attributes[:avatar_id] = fields['avatarHash']
      attributes[:bio]       = fields['bio']
      attributes[:url]       = fields['url']
      self
    end

    # Retrieve a URL to the avatar.
    # 
    # Valid values for options are:
    #   :large (170x170)
    #   :small (30x30)
    def avatar_url(options = { :size => :large })
      size = options[:size] == :small ? 30 : 170
      "https://trello-avatars.s3.amazonaws.com/#{avatar_id}/#{size}.png"
    end

    # Returns a list of the boards a member is a part of.
    #
    # The options hash may have a filter key which can have its value set as any
    # of the following values:
    #   :filter => [ :none, :members, :organization, :public, :open, :closed, :all ] # default: :all
    def boards(options = { :filter => :all })
      boards = Client.get("/members/#{username}/boards", options).json_into(Board)
      MultiAssociation.new(self, boards).proxy
    end

    # Returns a list of cards the member is assigned to.
    #
    # The options hash may have a filter key which can have its value set as any
    # of the following values:
    #    :filter => [ :none, :open, :closed, :all ] # default :open
    def cards(options = { :filter => :open })
      cards = Client.get("/members/#{username}/cards", options).json_into(Card)
      MultiAssociation.new(self, cards).proxy
    end

    # Returns a list of the organizations this member is a part of.
    #
    # The options hash may have a filter key which can have its value set as any
    # of the following values:
    #   :filter => [ :none, :members, :public, :all ] # default: all
    def organizations(options = { :filter => :all })
      orgs = Client.get("/members/#{username}/organizations", options).json_into(Organization)
      MultiAssociation.new(self, orgs).proxy
    end

    # Returns a list of notifications for the user
    def notifications
      notifications = Client.get("/members/#{username}/notifications").json_into(Notification)
      MultiAssociation.new(self, notifications).proxy
    end

    def save
      @previously_changed = changes
      @changed_attributes.clear

      return update! if id
    end

    def update!
      Client.put("/members/#{username}", {
        :displayName => full_name,
        :bio         => bio
      }).json_into(self)
    end

    # :nodoc:
    def request_prefix
      "/members/#{username}"
    end
  end
end
