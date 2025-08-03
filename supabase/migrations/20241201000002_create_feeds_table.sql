-- Create feeds table
CREATE TABLE IF NOT EXISTS feeds (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  media_urls TEXT[],
  jam_session_id UUID,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE feeds ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Feeds are viewable by everyone" ON feeds
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own feeds" ON feeds
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own feeds" ON feeds
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own feeds" ON feeds
  FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS feeds_user_id_idx ON feeds(user_id);
CREATE INDEX IF NOT EXISTS feeds_created_at_idx ON feeds(created_at DESC);
CREATE INDEX IF NOT EXISTS feeds_jam_session_id_idx ON feeds(jam_session_id); 