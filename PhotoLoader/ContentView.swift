import Combine
import SwiftUI

struct PhotoListView: View {
    @ObservedObject private var remote = Remote()

    @ViewBuilder
    var body: some View {
        if remote.photos.isEmpty {
            Text("Loading...")
                .onAppear {
                    self.remote.loadPhotos()
            }
        } else {
            List(remote.photos) { photo in
                NavigationLink(destination: PhotoView(downloadURL: photo.downloadURL)) {
                    Text(photo.author)
                }
            }
        }
    }
}

struct PhotoView: View {
    let downloadURL: String

    @State private var image = Image(systemName: "photo")
    @State private var cancellable: AnyCancellable?

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .onAppear {
                self.cancellable = URLSession.shared
                    .dataTaskPublisher(for: URL(string: self.downloadURL)!)
                    .map(\.data)
                    .map { data in
                        Image(uiImage: UIImage(data: data)!)
                    }
                    .catch { error in
                        Empty()
                    }
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.image, on: self)
            }
            .onDisappear {
                DispatchQueue.main.async {
                    self.cancellable = nil
                }
            }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            PhotoListView()
                .navigationBarTitle("Photos")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct Photo: Decodable, Identifiable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let downloadURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case width
        case height
        case url
        case downloadURL = "download_url"
    }
}

class Remote: ObservableObject {
    @Published var photos: [Photo] = []

    private var cancellable: AnyCancellable?

    func loadPhotos() {
        cancellable = URLSession.shared
            .dataTaskPublisher(for: URL(string: "https://picsum.photos/v2/list")!)
            .map(\.data)
            .decode(type: [Photo].self, decoder: JSONDecoder())
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.photos, on: self)
    }
}
