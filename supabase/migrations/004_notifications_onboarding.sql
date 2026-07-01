-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('reaction', 'comment', 'follow', 'system')),
  title text NOT NULL,
  body text NOT NULL,
  data jsonb DEFAULT '{}'::jsonb,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications (user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON public.notifications FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can mark their own notifications as read"
  ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Auto-create notification on reaction
CREATE OR REPLACE FUNCTION public.handle_reaction_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  post_owner uuid;
  reactor_name text;
BEGIN
  SELECT user_id INTO post_owner FROM public.posts WHERE id = NEW.post_id;
  IF post_owner IS NULL OR post_owner = NEW.user_id THEN RETURN NULL; END IF;
  SELECT COALESCE(display_name, username, 'Quelqu''un') INTO reactor_name FROM public.profiles WHERE id = NEW.user_id;
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (post_owner, 'reaction', 'Nouvelle reaction',
    reactor_name || ' a reagi a votre publication',
    jsonb_build_object('post_id', NEW.post_id, 'reaction_type', NEW.reaction_type));
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_reaction_insert ON public.reactions;
CREATE TRIGGER on_reaction_insert
  AFTER INSERT ON public.reactions
  FOR EACH ROW EXECUTE FUNCTION public.handle_reaction_notification();

-- Auto-create notification on comment
CREATE OR REPLACE FUNCTION public.handle_comment_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  post_owner uuid;
  commenter_name text;
BEGIN
  SELECT user_id INTO post_owner FROM public.posts WHERE id = NEW.post_id;
  IF post_owner IS NULL OR post_owner = NEW.user_id THEN RETURN NULL; END IF;
  SELECT COALESCE(display_name, username, 'Quelqu''un') INTO commenter_name FROM public.profiles WHERE id = NEW.user_id;
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (post_owner, 'comment', 'Nouveau commentaire',
    commenter_name || ' a commente votre publication: ' || LEFT(NEW.content, 50),
    jsonb_build_object('post_id', NEW.post_id));
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_comment_insert ON public.comments;
CREATE TRIGGER on_comment_insert
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_comment_notification();

-- Auto-create notification on follow
CREATE OR REPLACE FUNCTION public.handle_follow_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  follower_name text;
BEGIN
  SELECT COALESCE(display_name, username, 'Quelqu''un') INTO follower_name FROM public.profiles WHERE id = NEW.follower_id;
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (NEW.following_id, 'follow', 'Nouvel abonne',
    follower_name || ' vous suit maintenant',
    jsonb_build_object('follower_id', NEW.follower_id));
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_follow_insert ON public.follows;
CREATE TRIGGER on_follow_insert
  AFTER INSERT ON public.follows
  FOR EACH ROW EXECUTE FUNCTION public.handle_follow_notification();
