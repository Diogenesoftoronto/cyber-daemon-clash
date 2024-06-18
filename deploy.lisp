(org.shirakumo.fraf.trial.release:configure
 :build (:features (:kandria-release)
	 :prune ("pool/effects/"
		 "pool/workbench/"
		 "pool/trial/"
		 "pool/kandria/music/"
		 "pool/kandria/sound/"
		 "pool/kandria/*/*.ase"
		 "pool/music/*.wav"
		 "mods/*/"
		 "mods/*.zip"
		 "pool/**/*.*~"
		 "pool/**/#*#")
	 :copy (
		;; "CHANGELOG.md" ;; TODO: generate this based on git
		;; commits or just make one.
		"README.md"`
		("bin/pool/trial/fps-texture.png"
		 "pool/trial/fps-texture.png")))
 :depots (:linux ("*.so" "cyber-daemon-clash-linux.run")
	  :windows ("*.dll" "cyber-daemon-clash-windows.exe")
	  :macos ("*.dylib" "cyber-daemon-clash-macos.o")
	  :content ("pool/" "mods/" "lang/" "cyberspace.zip" "CHANGES.mess" "README.mess" "keymap.lisp"))
 :bundles (:linux (:depots (:linux :content))
	   :windows (:depots (:windows :content))
	   :macos (:depots (:macos :content))
	   :all (:depots (:linux :windows :macos :content)))
 ;; :keygen (:key "333B5B5C-9DDC-4E41-9C82-F2254330722E"
 ;;          :secret "DCBE2959-5231-4D22-85BF-F12A9C4781D1"
 ;;          :api-base ""
 ;;          :secrets ""
 ;;          :bundles (:linux 3
 ;;                    :windows 2))
 :itch (:user "Diogenesoftoronto"
	:bundles (:linux "cyber-daemon-clash:linux-64"
		  :windows "cyber-daemon-clash:windows-64"))
 ;; :steam (:branch "developer"
 ;;         :user "")
 ;; :gog (:user "NONE"
 ;;       :password "secure.gog.com"
 ;;       :branch ("Staging" "kCGTLpBC"))
 :upload (:targets #(:steam))
 :bundle (:targets #(:windows :linux))
 :system "cyber-daemon-clash")
