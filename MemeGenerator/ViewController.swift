//
//  ViewController.swift
//  MemeGenerator
//
//  Created by Huy Bui on 2022-12-11.
//

import UIKit
import LinkPresentation

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet var noPhotoMessage: UIStackView!
    @IBOutlet var imageView: UIImageView!
    
    private var image: UIImage? {
        didSet {
            if image == nil { // No image.
                imageView.image = nil
                noPhotoMessage?.isHidden = false // Show no photo message.
                navigationController?.isToolbarHidden = true // Hide tool bar.
                navigationItem.rightBarButtonItem?.isHidden = true // Hide share button.
            } else {
                imageView.image = image
                noPhotoMessage?.isHidden = true
                navigationController?.isToolbarHidden = false
                navigationItem.rightBarButtonItem?.isHidden = false
            }
        }
    }
    
    private var topText = "",
                bottomText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        
        title = "MemeGenerator"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPhoto))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(sharePhoto))
        navigationItem.rightBarButtonItem?.isHidden = true
        
        let deleteButton = UIButton(),
            flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            setTextButton = UIButton()
        
        deleteButton.configuration = UIButton.Configuration.plain()
        deleteButton.tintColor = .systemRed
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.configuration?.imagePadding = 5
        deleteButton.addTarget(self, action: #selector(discard), for: .touchUpInside)
        
        setTextButton.configuration = UIButton.Configuration.plain()
        setTextButton.setTitle("Set Text", for: .normal)
        setTextButton.addTarget(self, action: #selector(setText), for: .touchUpInside)
        
        toolbarItems = [UIBarButtonItem(customView: setTextButton), flexibleSpace, UIBarButtonItem(customView: deleteButton)]
    }
    
    @objc func importPhoto() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        self.image = image
        topText = ""; bottomText = ""
        setText()
    }
    
    @objc func sharePhoto() {
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.9) else { return }
        
        let activity = UIActivityViewController(activityItems: [imageData, self], applicationActivities: [])
        activity.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activity, animated: true)
    }
    
    @objc func setText() {
        let input = UIAlertController(title: "Set Text", message: nil, preferredStyle: .alert)
        input.addTextField()
        input.textFields?[0].placeholder = "Top Text"
        input.textFields?[0].text = topText
        
        input.addTextField()
        input.textFields?[1].placeholder = "Bottom Text"
        input.textFields?[1].text = bottomText
        
        input.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        input.addAction(UIAlertAction(title: "Set", style: .default) { [weak self] _ in
            self?.topText = input.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            self?.bottomText = input.textFields?[1].text?.trimmingCharacters(in: .whitespaces) ?? ""
            self?.renderImage()
        })
        
        present(input, animated: true)
    }
    
    @objc func discard() {
        let actionSheet = UIAlertController(title: nil, message: "This meme will be deleted. This action is irreversible.", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Delete Meme", style: .destructive) { [weak self] _ in
            self?.topText = ""; self?.bottomText = ""
            self?.image = nil
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    func renderImage() {
        guard let image = self.image else { return }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        let output = renderer.image { context in
            image.draw(at: CGPoint(x: 0, y: 0))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .font: UIFont(name: "Impact", size: image.size.width / 6)!,
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -4
            ]
            
            let attributedTopText = NSAttributedString(string: topText.uppercased(), attributes: attributes),
                attributedBottomText = NSAttributedString(string: bottomText.uppercased(), attributes: attributes)
            
            attributedTopText.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: image.size))
            attributedBottomText.draw(in: CGRect(origin: CGPoint(x: 0, y: image.size.height - (image.size.width / 5)), size: image.size))
        }
        
        self.imageView.image = output
    }
    
    func setupConstraints() {
        noPhotoMessage.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noPhotoMessage.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            noPhotoMessage.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }

}

// Share sheet image thumbnail & title.
// https://stackoverflow.com/a/61050991/19227228
extension ViewController: UIActivityItemSource {
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "\(topText) \(bottomText)"
        metadata.imageProvider = NSItemProvider(object: imageView.image!)
        return metadata
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return NSObject()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }
}
