import Sound.MIDI.Message.Channel
import Sound.MIDI.Message.Channel.Voice
import Sound.MIDI.File.Load
import Sound.MIDI.File
import qualified Data.EventList.Relative.TimeBody as TimeBody
import Sound.MIDI.File.Event
import Sound.MIDI.File.Event.Meta

import qualified Graphics.UI.Gtk.Gdk.Events as G
import qualified Graphics.UI.Gtk.Gdk.Pixmap as G
import qualified Graphics.UI.Gtk as G
import qualified Graphics.Rendering.Cairo as C
import qualified Graphics.Rendering.Cairo.Matrix as M

import Control.Monad
import System as System
import System.IO
import Data.List
import Data.Maybe
import Data.IORef

uncurry3 f (x,y,z) = f x y z
curry3 f x y z = f (x,y,z)

evalTimeDeltas :: Integer -> [(Integer,a)] -> [(Integer,a)]
evalTimeDeltas d [] = []
evalTimeDeltas d ((a,b):xs) = (a+d,b):evalTimeDeltas (a+d) xs

grpNotes ns ts [] = []
grpNotes ns ts ((t,msg):xs) = case messageBody msg of 
	Voice (NoteOn pitch _) -> let n = (fromChannel$messageChannel msg, fromPitch$pitch) in (map (\((c,p),ton) -> (c,p,ton,t)) $ filter ((==n).fst) ts) ++ grpNotes (n:filter(/=n) ns) ((n,t):filter ((/=n).fst) ts) xs
	Voice (NoteOff pitch _) -> let n = (fromChannel$messageChannel msg, fromPitch$pitch) in (map (\((c,p),ton) -> (c,p,ton,t)) $ filter ((==n).fst) ts) ++ grpNotes (filter(/=n) ns) (filter ((/=n).fst) ts) xs
	_ -> grpNotes ns ts xs 

main2 = do
  score <- System.getArgs
	>>= fromFile . head
	>>= return . map show . filter (not.null) . map (\trk ->
	  let a = concat $ intersperse ": " $ filter (not.null) $
		map (\x -> case x of
			TrackName n -> n
			_ -> ""
		 ) (TimeBody.getBodies $ TimeBody.mapMaybe maybeMetaEvent trk)
	  in map (\(c, p, ton, toff) -> (a, c, p, ton, toff)) $
		grpNotes [] [] $ evalTimeDeltas 0 $ map (\(a,b) -> (fromElapsedTime a, b)) $
		TimeBody.toPairList $ TimeBody.mapMaybe maybeMIDIEvent trk
	 ) . getTracks . Sound.MIDI.File.explicitNoteOff
  mapM_ putStrLn score

--main = System.getArgs >>= fromFile . head >>= Prelude.mapM (putStrLn . show) . getTracks . Sound.MIDI.File.explicitNoteOff
--main = System.getArgs >>= fromFile . head >>= Prelude.mapM (putStrLn . show) . evalTimeDeltas 0 . map (\(a,b) -> (fromElapsedTime a, b)) . TimeBody.toPairList . TimeBody.mapMaybe maybeMIDIEvent . head . tail . tail . getTracks . Sound.MIDI.File.explicitNoteOff
--
--main = System.getArgs >>= fromFile . head >>= Prelude.mapM (putStrLn . show) . grpNotes [] [] . evalTimeDeltas 0 . map (\(a,b) -> (fromElapsedTime a, b)) . TimeBody.toPairList . TimeBody.mapMaybe maybeMIDIEvent . head . tail . tail . getTracks . Sound.MIDI.File.explicitNoteOff

main = do
  G.initGUI
  window <- G.windowNew
--  G.windowSetResizable window False
  G.windowSetDefaultSize window 800 300
  -- press any key to quit
  --G.onKeyPress window $ const (do G.widgetDestroy window; return True)
  G.onDestroy window G.mainQuit

  zoom <- G.vScaleNewWithRange 10 1000 10
  G.rangeSetValue zoom 100

  score <- System.getArgs
	>>= fromFile . head
	>>= return . concat . map (\trk ->
	  let a = concat $ intersperse ": " $ filter (not.null) $
		map (\x -> case x of
			TrackName n -> n
			_ -> ""
		 ) (TimeBody.getBodies $ TimeBody.mapMaybe maybeMetaEvent trk)
	  in map (\(c, p, ton, toff) -> (a, c, p, ton, toff)) $
		grpNotes [] [] $ evalTimeDeltas 0 $ map (\(a,b) -> (fromElapsedTime a, b)) $
		TimeBody.toPairList $ TimeBody.mapMaybe maybeMIDIEvent trk
	 ) . getTracks . Sound.MIDI.File.explicitNoteOff
  let
	parts = nub $ sort $ map (\(s, v, _, _, _) -> (s,v)) score
	right = maximum (map (\(_,_,_,_,x) -> realToFrac x) score)
	portion = G.rangeGetValue zoom >>= return . (* realToFrac (minimum (filter (>0) $ map (\(_,_,_,ton,toff) -> toff - ton) score)))
   in do
   portion >>= putStrLn . show
   part_options <- mapM G.checkButtonNewWithLabel $ zipWith (\n pt -> show n ++ if null pt then "" else ": " ++ pt) [1..] (map fst parts)
--   part_options <- mapM G.checkButtonNewWithLabel $ zipWith (\n pt -> show n ++ if null pt then "" else ": " ++ pt) [1..] parts
   let
	part_check = mapM G.toggleButtonGetActive part_options >>= return . map snd . filter fst . flip zip (zip parts [0..])
    in do
    canvas <- G.drawingAreaNew
    hAdj <- portion >>= G.adjustmentNew 0 0 right (right/100) (right/50)
    hScr <- G.hScrollbarNew hAdj
    
    surface <- newIORef Nothing
  --G.onLoad canvas $ const $ create score canvas 800 300
    G.onExpose canvas $ redraw surface score part_check canvas
    --G.onConfigure canvas $ const $ recreate surface score canvas (floor right)
    G.onConfigure canvas $ const $ recreate surface score part_check canvas hAdj
    G.afterValueChanged hAdj $ do
	recreate surface score part_check canvas hAdj
	G.widgetQueueDraw canvas
    G.afterRangeValueChanged zoom $ do
	portion >>= G.adjustmentSetPageSize  hAdj
	recreate surface score part_check canvas hAdj
	G.widgetQueueDraw canvas
    hBox <- G.hBoxNew False 0
    mapM (\b -> do
	  G.toggleButtonSetActive b True
	  G.afterToggled b $ recreate surface score part_check canvas hAdj >> G.widgetQueueDraw canvas
	  G.boxPackStart hBox b G.PackNatural 0
	) part_options
    scr <- G.scrolledWindowNew Nothing Nothing
    G.scrolledWindowSetPolicy scr G.PolicyAutomatic G.PolicyNever
    G.scrolledWindowAddWithViewport scr hBox
    vBox <- G.vBoxNew False 0
    G.boxPackStart vBox canvas G.PackGrow 0
    G.boxPackStart vBox scr G.PackNatural 0
    G.boxPackStart vBox hScr G.PackNatural 0
    hBox2 <- G.hBoxNew False 0
    G.boxPackStart hBox2 vBox G.PackGrow 0
    G.boxPackStart hBox2 zoom G.PackNatural 0
    G.set window [G.containerChild G.:= hBox2]
    G.widgetShowAll window
    G.mainGUI
  
redraw surface score parts canvas ev =
 let G.Rectangle x y w h = G.eventArea ev in do
  win <- G.widgetGetDrawWindow canvas
  (width, height) <- G.widgetGetSize canvas
--  adjX <- G.adjustmentGetValue hAdj
  (surface',gc) <- readIORef surface >>= maybe (create surface score canvas width height) return
--  G.drawDrawable win gc surface' w h x y x y
--  G.drawDrawable win gc surface' 0 0 0 0 width height
--  G.drawDrawable win gc surface' (x + (floor adjX)) y x y width height
  G.drawDrawable win gc surface' x y x y width height
--  G.renderWithDrawable win $ draw score width height
  return True

create surface score canvas w h = do
	win <- G.widgetGetDrawWindow canvas
	surface' <- G.pixmapNew (Just win) w h Nothing
	gc <- G.gcNew win
	writeIORef surface (Just (surface',gc))
	return (surface',gc)

recreate surface score parts canvas hAdj = do
  win <- G.widgetGetDrawWindow canvas
  (width, height) <- G.widgetGetSize canvas
  (surface',gc) <- create surface score canvas width height
  adjX <- G.adjustmentGetValue hAdj
  right <- G.adjustmentGetPageSize  hAdj
  let score' = filter (\(_,_,_,ton,toff) -> realToFrac toff > adjX && realToFrac ton < adjX + right) score in do
--   putStrLn $ show $ length score'
--   hFlush stdout
   parts >>= G.renderWithDrawable surface' . draw score' width height adjX right
   writeIORef surface (Just (surface',gc))
   return True

{-
create score canvas w h = do
--  C.withImageSurface C.FormatARGB32 width height $ flip C.renderWith $ draw score width height
  surface' <- C.createImageSurface C.FormatARGB32 w h
  C.renderWith surface' $ draw score w h
  newIORef surface'

recreate surface score canvas = do
  win <- G.widgetGetDrawWindow canvas
  (width, height) <- G.widgetGetSize canvas
--  C.withImageSurface C.FormatARGB32 width height $ flip C.renderWith $ draw score width height
  surface' <- C.createImageSurface C.FormatARGB32 width height
  C.renderWith surface' $ draw score width height
  writeIORef surface surface'
  return True
-}
--colours x = head $ drop x $ cycle pal
colours x = cycle pal !! x
 where
	pal = [
		(0,0,0),
		(1,0,0),
		(0,1,0),
		(0,0,1),
		(1,1,0),
		(0,1,1),
		(1,0,1),
		(0.8,1,0),
		(0.8,0,1),
		(1,0,0.80),
		(0,1,0.80),
		(1,0.80,0),
		(0,0.80,1),
		(0.8,0.8,0),
		(0.8,0,0.8),
		(0.8,0,0.80),
		(0,0.8,0.80),
		(0.8,0.80,0),
		(0,0.80,0.8)
	 ]

--draw :: a -> Double -> Double -> C.Render ()
--draw :: a -> Int -> Int -> C.Render ()
draw score width height adjX right parts =
  let
   in do
	C.rectangle 0 0 (realToFrac width) (realToFrac height)
	C.setSourceRGB 1 1 1
	C.fill
	C.setLineWidth 0.7
	--C.setSourceRGB 0 0 0
  	C.setDash [] 0
	C.setSourceRGB 0.5 0.5 0.5
	C.translate 0 (realToFrac height/2)
	C.scale (realToFrac width / right) (realToFrac height / top/2) 
	sequence_ $ map (octave right) [o..o']
	C.scale (right / realToFrac width) (2*top/realToFrac height)
	clef 0
	C.scale (realToFrac width / right) (realToFrac height / top/2) 
	C.translate (-adjX) 0
	C.setSourceRGB 0 0 0
	sequence_ $ map (endmk right) score
	sequence_ $ map (note right) score
	where
	  pitches = map (\(s, v, p, ton, toff) -> p - 60) score
	  o = realToFrac $ minimum pitches `quot` 12 - 2
	  o' = realToFrac $ maximum pitches `quot` 12 + 2
  	  top = (max (abs o') (abs o)) * 60
	  octave right n = do
		C.translate 0 (-n*60)
		C.moveTo 0 (-30)
		C.lineTo right (-30)
		C.setDash [4.0, 1.0, 4.0] (5000/right)
		C.stroke
		C.moveTo 0 (-60)
		C.lineTo right (-60)
		C.moveTo 0 0
		C.lineTo right 0
		C.setDash [] 0
		C.stroke
 		C.translate 0 (n*60)
	  endmk :: Double ->  (String, Int, Int, Integer, Integer) -> C.Render ()
	  endmk right (s, v, p, ton, toff) = do
	    	C.save
		C.setSourceRGB 0.7 0.7 0.7
		C.setLineWidth 0.7
		C.translate (realToFrac toff) 0
		C.moveTo 0 (-top)
		C.lineTo 0 top
		C.stroke
		C.restore
	  note :: Double ->  (String, Int, Int, Integer, Integer) -> C.Render ()
	  note right (s, v, p, ton, toff) =
	    let
	    	(q,r) = quotRem (p+1) 3
	    	x = realToFrac $ -(q-20)*15
	    in
	     maybe (return ()) (\colour -> do
		C.save
		uncurry3 C.setSourceRGB (colours colour)
		C.setDash [] 0
		C.setLineWidth 1.2
		C.translate (realToFrac ton) x
		C.moveTo 0 0
		C.lineTo (realToFrac (toff-ton)) 0
		C.scale (right / realToFrac width) (2*top/realToFrac height)
		C.relMoveTo 0 2 
		C.relLineTo 0 (-4) 
		C.stroke
		C.setLineWidth 1.5
		when (r == 1) $ do
			C.moveTo 2 0
	 		C.arc 0 0 2 0 (pi*2)
	 		C.setSourceRGB 1 1 1
			C.fill
	 		C.arc 0 0 2 0 (pi*2)
			C.setSourceRGB 0 0 0
			C.stroke
	 	when (r /= 1) $ do
   			C.moveTo 0 0 
			C.lineTo (7) (realToFrac (1-r)*7)
			C.stroke
		C.restore
	      ) $ lookup (s,v) parts
	  clef pitch = do
		C.translate 10 0
		C.save
		C.translate (-5) 0
		C.setLineWidth 1.5
		C.moveTo 0 0
 		C.arc 0 0 4 (pi/2) (-pi/2)
		C.stroke
		C.setLineWidth 2.0
		C.moveTo 0 (-(realToFrac height))
		C.lineTo 0 (realToFrac height)
		C.moveTo 0 0
		C.lineTo right 0
		C.stroke
		C.restore

