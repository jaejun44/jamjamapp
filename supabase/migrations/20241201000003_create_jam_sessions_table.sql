-- Create jam_sessions table
CREATE TABLE IF NOT EXISTS jam_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  instruments TEXT[],
  max_participants INTEGER,
  current_participants INTEGER DEFAULT 1,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'full', 'closed', 'cancelled')),
  scheduled_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE jam_sessions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Jam sessions are viewable by everyone" ON jam_sessions
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own jam sessions" ON jam_sessions
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Users can update their own jam sessions" ON jam_sessions
  FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "Users can delete their own jam sessions" ON jam_sessions
  FOR DELETE USING (auth.uid() = creator_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS jam_sessions_creator_id_idx ON jam_sessions(creator_id);
CREATE INDEX IF NOT EXISTS jam_sessions_status_idx ON jam_sessions(status);
CREATE INDEX IF NOT EXISTS jam_sessions_created_at_idx ON jam_sessions(created_at DESC); 