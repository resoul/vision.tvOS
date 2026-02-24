import UIKit

final class RezkaTestViewController: UIViewController {

    private let filmURL = "https://rezka.ag/films/horror/13885-vatikanskie-zapisi-2015.html"

    private let textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isSelectable = false
        tv.font = .monospacedSystemFont(ofSize: 28, weight: .regular)
        tv.backgroundColor = .black
        tv.textColor = .white
        tv.textContainerInset = UIEdgeInsets(top: 40, left: 60, bottom: 40, right: 60)
        return tv
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.translatesAutoresizingMaskIntoConstraints = false
        s.hidesWhenStopped = true
        s.color = .white
        return s
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        runTest()
    }

    private func setupUI() {
        view.addSubview(textView)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Test

    private func runTest() {
        log("⏳ Fetching page...")
        spinner.startAnimating()

        // Test 1: parse film page
        RezkaFetcher.shared.fetchPlayerData(url: filmURL) { [weak self] result in
            guard let self else { return }
            self.spinner.stopAnimating()
            switch result {
            case .success(let data): self.handleSuccess(data)
            case .failure(let error): self.log("❌ ERROR: \(error.localizedDescription)")
            }
        }

        // Test 2: search
        RezkaFetcher.shared.search(query: "Ватиканские записи") { [weak self] result in
            switch result {
            case .success(let results):
                var out = "\n─── SEARCH RESULTS (\(results.count)) ───\n"
                for r in results {
                    out += "  [\(r.id)] \(r.category) · \(r.title)\n"
                    out += "    \(r.info)"
                    if let s = r.status { out += " · \(s)" }
                    out += "\n"
                    out += "    🖼 \(r.posterURL?.absoluteString ?? "no poster")\n"
                    out += "    🔗 \(r.url.absoluteString)\n"
                }
                self?.log(out)
            case .failure(let error):
                self?.log("❌ SEARCH ERROR: \(error.localizedDescription)")
            }
        }
    }

    private func handleSuccess(_ data: RezkaPlayerData) {
        var output = ""

        output += "✅ MOVIE ID: \(data.movieId)\n"
        output += "🎙 ACTIVE TRANSLATOR ID: \(data.activeTranslatorId)\n"
        output += "📺 DEFAULT QUALITY: \(data.defaultQuality)\n"
        output += "🔑 FAVS: \(data.favs)\n\n"

        // Translators
        output += "─── TRANSLATORS (\(data.translators.count)) ───\n"
        for t in data.translators {
            let active = t.isActive ? " ✓" : ""
            output += "  [\(t.translatorId)] \(t.title)\(active)\n"
        }

        // Streams
        output += "\n─── STREAMS (\(data.streams.count)) ───\n"
        for s in data.streams {
            output += "  [\(s.quality)]\n"
            output += "    HLS: \(s.hlsURL?.absoluteString ?? "nil")\n"
            output += "    MP4: \(s.directURL?.absoluteString ?? "nil")\n"
        }

        // Target HLS for default quality
        let hls = data.streams.first(where: { $0.quality == data.defaultQuality })?.hlsURL
        output += "\n🎯 HLS for default quality (\(data.defaultQuality)):\n  \(hls?.absoluteString ?? "NOT FOUND")\n"

        log(output)

        // Phase 2: test switching to a different translator
        if let otherTranslator = data.translators.first(where: { !$0.isActive }) {
            testTranslatorSwitch(data, translator: otherTranslator)
        }
    }

    private func testTranslatorSwitch(_ data: RezkaPlayerData, translator: RezkaTranslator) {
        log("\n⏳ Switching to translator: [\(translator.translatorId)] \(translator.title)...")

        RezkaFetcher.shared.fetchStreams(
            movieId:      data.movieId,
            translatorId: translator.translatorId,
            favs:         data.favs,
            isCamrip:     translator.isCamrip,
            isAds:        translator.hasAds,
            isDirector:   translator.isDirector
        ) { [weak self] result in
            switch result {
            case .success(let streams):
                var out = "✅ Got \(streams.count) streams for [\(translator.translatorId)]:\n"
                for s in streams {
                    out += "  [\(s.quality)] HLS: \(s.hlsURL?.absoluteString ?? "nil")\n"
                }
                self?.log(out)
            case .failure(let error):
                self?.log("❌ Translator switch failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    private func log(_ text: String) {
        print(text)
        DispatchQueue.main.async {
            self.textView.text += text + "\n"
            let bottom = self.textView.contentSize.height - self.textView.bounds.height
            if bottom > 0 {
                self.textView.setContentOffset(CGPoint(x: 0, y: bottom), animated: false)
            }
        }
    }
}
