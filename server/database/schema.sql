-- PostgreSQL needs this extension to generate UUIDs automatically
-- gen_random_uuid() generates a new UUID each time it is called
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ENUMs must be created before tables that use them
-- PostgreSQL enforces that only defined values can be stored
CREATE TYPE user_role AS ENUM ('user', 'admin', 'moderator');
CREATE TYPE listing_type_enum AS ENUM ('item', 'service');
CREATE TYPE trade_status AS ENUM (
    'draft', 'listed', 'proposed', 'negotiating',
    'accepted', 'in_progress', 'completed',
    'rejected', 'cancelled', 'expired', 'disputed'
);
CREATE TYPE notification_type AS ENUM (
    'trade_offer', 'message', 'match', 'review', 'system'
);
CREATE TYPE report_status AS ENUM ('pending', 'reviewed', 'resolved');
CREATE TYPE category_type AS ENUM ('item', 'service', 'both');

-- First create table of locations because it depends on nothing
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    city VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    country VARCHAR(100) NOT NULL,

    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7)
);

-- Now create table of categories because they can depends on parent category
-- Special case self-referencing foriegn key
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(150) NOT NULL,

    type category_type NOT NULL,

    parent_category_id UUID
        REFERENCES categories(id)
        ON DELETE SET NULL,

    icon_url VARCHAR(500)
);

-- Create table of users it depends on nothing. It stores login/security info
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    email VARCHAR(255) UNIQUE NOT NULL,

    password_hash VARCHAR(255) NOT NULL,

    role user_role NOT NULL DEFAULT 'user',

    is_verified BOOLEAN DEFAULT FALSE,

    is_banned BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    last_login TIMESTAMP WITH TIME ZONE
);

-- Create table of users_profiles.
-- Security data and profile data should be separated. Users table:authentication, Profiles table:public profile information

CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL UNIQUE
        REFERENCES users(id)
        ON DELETE CASCADE,

    username VARCHAR(100) UNIQUE NOT NULL,

    full_name VARCHAR(150),

    bio TEXT,

    avatar_url VARCHAR(500),

    city VARCHAR(100),

    country VARCHAR(100),

    reputation_score DECIMAL(5,2) DEFAULT 0,

    total_trades INTEGER DEFAULT 0
);

-- Create table of listings
-- Represents items/services users want to trade.
CREATE TABLE listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    category_id UUID NOT NULL
        REFERENCES categories(id)
        ON DELETE RESTRICT,

    title VARCHAR(255) NOT NULL,

    description TEXT NOT NULL,

    listing_type listing_type_enum NOT NULL,

    status trade_status NOT NULL DEFAULT 'draft',

    estimated_value DECIMAL(10,2),

    location_id UUID
        REFERENCES locations(id)
        ON DELETE SET NULL,

    wants_description TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    expires_at TIMESTAMP WITH TIME ZONE,

    view_count INTEGER DEFAULT 0
);

-- Create table of listing images. One listing can have many images
CREATE TABLE listing_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    listing_id UUID NOT NULL
        REFERENCES listings(id)
        ON DELETE CASCADE,

    image_url VARCHAR(500) NOT NULL,

    is_primary BOOLEAN DEFAULT FALSE,

    upload_order INTEGER DEFAULT 0
);

-- Create table of trade offers. It represent barter proposal offers
CREATE TABLE trade_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    proposer_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    receiver_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    proposer_listing_id UUID NOT NULL
        REFERENCES listings(id)
        ON DELETE CASCADE,

    receiver_listing_id UUID NOT NULL
        REFERENCES listings(id)
        ON DELETE CASCADE,

    status trade_status NOT NULL DEFAULT 'proposed',

    message TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create table of trade negotiations. It stores counter offers
CREATE TABLE trade_negotiations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    trade_offer_id UUID NOT NULL
        REFERENCES trade_offers(id)
        ON DELETE CASCADE,

    proposed_by UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    terms_description TEXT NOT NULL,

    counter_number INTEGER DEFAULT 1,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create table of conversations. One trade →one chat room
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    trade_offer_id UUID UNIQUE NOT NULL
        REFERENCES trade_offers(id)
        ON DELETE CASCADE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create table of messages. Messages inside conversations
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    conversation_id UUID NOT NULL
        REFERENCES conversations(id)
        ON DELETE CASCADE,

    sender_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    content TEXT NOT NULL,

    is_read BOOLEAN DEFAULT FALSE,

    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create table of reviews. User feedback after trade completion
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    trade_offer_id UUID NOT NULL
        REFERENCES trade_offers(id)
        ON DELETE CASCADE,

    reviewer_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    reviewed_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),

    comment TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create table of notifications for User alerts
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    type notification_type NOT NULL,

    title VARCHAR(255) NOT NULL,

    body TEXT,

    is_read BOOLEAN DEFAULT FALSE,

    reference_id UUID,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create table of reports. Abuse/moderation reports
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    reporter_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    reported_user_id UUID
        REFERENCES users(id)
        ON DELETE SET NULL,

    reported_listing_id UUID
        REFERENCES listings(id)
        ON DELETE SET NULL,

    reason TEXT NOT NULL,

    status report_status NOT NULL DEFAULT 'pending',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create table of admin_logs. Tracks admin/moderator actions
CREATE TABLE admin_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    admin_id UUID NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    action VARCHAR(255) NOT NULL,

    target_type VARCHAR(100),

    target_id UUID,

    notes TEXT,

    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes speed up queries on columns used in WHERE clauses frequent (time complexity0log(n))
-- Without an index, finding all listings for a user requires PostgreSQL to read every single row in the listings table and check user_id one by one. This is called a full table scan — O(n) time complexity.
CREATE INDEX idx_listings_user_id
ON listings(user_id);

CREATE INDEX idx_listings_status
ON listings(status);

CREATE INDEX idx_listings_category_id
ON listings(category_id);

CREATE INDEX idx_trade_offers_proposer
ON trade_offers(proposer_id);

CREATE INDEX idx_trade_offers_receiver
ON trade_offers(receiver_id);

CREATE INDEX idx_messages_conversation
ON messages(conversation_id);

CREATE INDEX idx_notifications_user
ON notifications(user_id);