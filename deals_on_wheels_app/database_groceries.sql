-- Create groceries table for grocery list feature
CREATE TABLE groceries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  item_name TEXT NOT NULL,
  quantity TEXT,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX idx_groceries_user_id ON groceries(user_id);
CREATE INDEX idx_groceries_completed ON groceries(completed);
CREATE INDEX idx_groceries_user_completed ON groceries(user_id, completed);
