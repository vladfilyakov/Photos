//
//  ViewController.swift
//  MyPhotos
//
//  Created by Vladislav Filyakov on 1/8/20.
//  Copyright © 2020 Vlad Filyakov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private enum ImageSize: CaseIterable {
        case small
        case medium
        case large

        var numberOfColumns: Int {
            switch self {
            case .small:
                return 4
            case .medium:
                return 2
            case .large:
                return 1
            }
        }

        var displayName: String {
            switch self {
            case .small:
                return "Small"
            case .medium:
                return "Medium"
            case .large:
                return "Large"
            }
        }

    }

    private let photos = Photos()

    private lazy var photosView = UICollectionView(frame: .zero, collectionViewLayout: PhotosLayout(photos: photos))
    private var photosLayout: PhotosLayout {
        guard let photosLayout = photosView.collectionViewLayout as? PhotosLayout else {
            fatalError("Collection view has a wrong layout class")
        }
        return photosLayout
    }
    private lazy var imageSizeSelector: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ImageSize.allCases.map { $0.displayName })
        segmentedControl.addTarget(self, action: #selector(handleImageSizeChanged), for: .valueChanged)
        return segmentedControl
    }()

    private var imageSize: ImageSize = .small {
        didSet {
            updatePhotosLayout()
        }
    }

    private var anchorIndex: Int = 0 {
        didSet {
            photosLayout.anchorIndex = anchorIndex
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        photosView.dataSource = self
        photosView.delegate = self
        photosView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        photosView.frame = view.bounds
        photosView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(photosView)
        //!!!
        photosView.backgroundColor = .orange

        updatePhotosLayout()

        toolbarItems = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: imageSizeSelector),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]

        imageSizeSelector.selectedSegmentIndex = imageSize.index
    }

    private func updatePhotosLayout() {
        photosLayout.numberOfColumns = imageSize.numberOfColumns
    }

    @objc private func handleImageSizeChanged() {
        imageSize = ImageSize.allCases[imageSizeSelector.selectedSegmentIndex]
    }
}

// MARK: - ViewController: UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 300
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        //!!!
        cell.backgroundColor = .cyan
        let label = cell.contentView.subviews.first as? UILabel ?? {
            let label = UILabel()
            label.textAlignment = .center
            label.frame = cell.contentView.bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cell.contentView.addSubview(label)
            return label
        }()

        let actualIndex = anchorIndex + indexPath.item
        label.text = photos.captionForItem(at: actualIndex)

        return cell
    }
}

// MARK: - ViewController: UICollectionViewDelegateFlowLayout

extension ViewController: UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //!!!
        if scrollView.contentSize == .zero {
            return
        }

        let contentOffsetBuffer = scrollView.bounds.height
        let deadZoneBuffer = scrollView.bounds.height

        if scrollView.contentOffset.y < contentOffsetBuffer {
            let newAnchorOffset = scrollView.bounds.maxY + contentOffsetBuffer - scrollView.contentSize.height + deadZoneBuffer
            if let indexPath = photosLayout.indexPathForFirstItem(at: newAnchorOffset), indexPath.item < 0 {
                let contentOffsetChange = photosLayout.verticalOffsetForItem(at: indexPath)
                anchorIndex -= -indexPath.item
                scrollView.contentOffset.y += -contentOffsetChange
            }
        }

        if scrollView.bounds.maxY > scrollView.contentSize.height - contentOffsetBuffer {
            let newAnchorOffset = scrollView.contentOffset.y - contentOffsetBuffer - deadZoneBuffer
            if let indexPath = photosLayout.indexPathForFirstItem(at: newAnchorOffset) {
                let contentOffsetChange = photosLayout.verticalOffsetForItem(at: indexPath)
                anchorIndex += indexPath.item
                scrollView.contentOffset.y -= contentOffsetChange
            } else {
                fatalError()
            }
        }
    }
}