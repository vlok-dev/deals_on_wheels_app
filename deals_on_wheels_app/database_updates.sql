-- Add image_url column to posts table
ALTER TABLE posts ADD COLUMN image_url TEXT;

-- Add suburb and shop columns for more specific deals
ALTER TABLE posts ADD COLUMN suburb TEXT;
ALTER TABLE posts ADD COLUMN shop TEXT;
ALTER TABLE posts ADD COLUMN shop_location TEXT; -- NEW: Specific store location

-- Add Google Maps location data
ALTER TABLE posts ADD COLUMN shop_latitude DOUBLE PRECISION;
ALTER TABLE posts ADD COLUMN shop_longitude DOUBLE PRECISION;
ALTER TABLE posts ADD COLUMN google_place_id TEXT;

-- Create storage bucket for deal images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('deal-images', 'deal-images', true);

-- Allow public access to deal images
CREATE POLICY "Public Access" ON storage.objects 
FOR SELECT USING (bucket_id = 'deal-images');

-- Allow authenticated users to upload deal images
CREATE POLICY "Authenticated users can upload deal images" ON storage.objects 
FOR INSERT WITH CHECK (
  bucket_id = 'deal-images' 
  AND auth.role() = 'authenticated'
);

-- Allow users to update their own uploaded images
CREATE POLICY "Users can update own deal images" ON storage.objects 
FOR UPDATE USING (
  bucket_id = 'deal-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own uploaded images
CREATE POLICY "Users can delete own deal images" ON storage.objects 
FOR DELETE USING (
  bucket_id = 'deal-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
