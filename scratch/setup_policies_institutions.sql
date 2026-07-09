CREATE POLICY "Public Access Institutions" ON storage.objects FOR SELECT USING (bucket_id = 'institutions');

CREATE POLICY "Admin Upload Institutions" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'institutions' AND (storage.foldername(name))[1] = (SELECT institution_id::text FROM public.profiles WHERE id = auth.uid() AND role = 'sudo' LIMIT 1));

CREATE POLICY "Admin Update Institutions" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'institutions' AND (storage.foldername(name))[1] = (SELECT institution_id::text FROM public.profiles WHERE id = auth.uid() AND role = 'sudo' LIMIT 1));

CREATE POLICY "Admin Delete Institutions" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'institutions' AND (storage.foldername(name))[1] = (SELECT institution_id::text FROM public.profiles WHERE id = auth.uid() AND role = 'sudo' LIMIT 1));
