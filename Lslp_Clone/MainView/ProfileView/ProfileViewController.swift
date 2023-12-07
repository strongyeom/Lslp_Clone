//
//  ProfileViewController.swift
//  Lslp_Clone
//
//  Created by 염성필 on 2023/12/02.
//

import UIKit
import RxSwift
import RxCocoa
import PhotosUI
import Kingfisher

class ProfileViewController : BaseViewController {
    
    let profileImage = PostImage("person.fill", color: .blue)
    let nickname = {
        let view = UILabel()
        view.text = "닉네임 입니다."
        view.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return view
    }()
    
    var postCount = {
        let view = UILabel()
        view.aggregateStatusCount()
        return view
    }()
    
    let post = {
        let view = UILabel()
        view.aggregateStatus(text: "게시물")
        return view
    }()
    
    var followersCount = {
        let view = UILabel()
        view.aggregateStatusCount()
        return view
    }()
    
    let followers = {
        let view = UILabel()
        view.aggregateStatus(text: "팔로워")
        return view
    }()
    
    var followingCount = {
        let view = UILabel()
        view.aggregateStatusCount()
        return view
    }()
    
    let following = {
        let view = UILabel()
        view.aggregateStatus(text: "팔로잉")
        return view
    }()
    
    let profileEdit = {
        let btn = UIButton()
        btn.setCornerButton(text: "프로필 편집", brandColor: .lightGray)
        return btn
    }()
    
    let profileShare = {
        let btn = UIButton()
        btn.setCornerButton(text: "프로필 공유", brandColor: .lightGray)
        return btn
    }()
    
    
    // MARK: - StackView
    lazy var buttonStackView = {
        let stack = UIStackView(arrangedSubviews: [profileEdit, profileShare])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()
    lazy var postStackView = {
        let stack = UIStackView(arrangedSubviews: [postCount, post])
        stack.axis = .vertical
        stack.spacing = 5
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    lazy var followersStackView = {
        let stack = UIStackView(arrangedSubviews: [followersCount, followers])
        stack.axis = .vertical
        stack.spacing = 5
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    lazy var followingStackView = {
        let stack = UIStackView(arrangedSubviews: [followingCount, following])
        stack.axis = .vertical
        stack.spacing = 5
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    
    lazy var horizonTalStackView = {
        let stack = UIStackView(arrangedSubviews: [postStackView, followersStackView, followingStackView])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.distribution = .fillEqually
        return stack
    }()
    
    
    // MARK: - Subject And Properties
    var selectedImageData = PublishSubject<Data>()
    let profileViewModel = ProfileViewModel()
    let disposeBag = DisposeBag()
    var imageData: String?
    
    override func configure() {
        super.configure()
        navigationItem.title = "마이페이지"
        print("ProfileViewController - configure")
        [profileImage, nickname, buttonStackView, horizonTalStackView].forEach {
            view.addSubview($0)
        }
        
        
        
        bind()
        
        
    }
    
    func bind() {
        
        APIManager.shared.requestGetProfile(api: Router.getProfile(accessToken: UserDefaultsManager.shared.accessToken))
            .share(replay: 1)
            .asDriver(onErrorJustReturn: GetProfileResponse(posts: [], followers: [Creator(_id: "", nick: "")], following: [Creator(_id: "", nick: "")], _id: "", email: "", nick: "", profile: imageData))
            .drive(with: self, onNext: { owner, response in
                dump(response)
                self.nickname.text = response.nick
                self.postCount.text = "\(response.posts.count)"
                self.followersCount.text = "\(response.followers.count)"
                self.followingCount.text = "\(response.following.count)"
                
                
                let imageDownloadRequest = AnyModifier { request in
                    var requestBody = request
                    requestBody.setValue(APIKey.secretKey, forHTTPHeaderField: "SesacKey")
                    requestBody.setValue(UserDefaultsManager.shared.accessToken, forHTTPHeaderField: "Authorization")
                    return requestBody
                }
                
                guard let imageString = response.profile else { return }
                let url = URL(string: BaseAPI.baseUrl + imageString)
                self.profileImage.kf.setImage(with: url, options: [ .requestModifier(imageDownloadRequest), .cacheOriginalImage])
                
            })
            .disposed(by: disposeBag)
        
        let tapGesture = UITapGestureRecognizer()
        self.profileImage.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .bind(with: self) { owner, tap in
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let photoLibray = UIAlertAction(title: "갤러리", style: .default) { [weak self] _ in
                    guard let self else { return }
                    var config = PHPickerConfiguration()
                    config.selectionLimit = 1
                    config.filter = .images
                    let picker = PHPickerViewController(configuration: config)
                    picker.delegate = self
                    self.present(picker, animated: true)
                }
                
                let cancel = UIAlertAction(title: "취소", style: .cancel)
                
                actionSheet.addAction(photoLibray)
                actionSheet.addAction(cancel)
                owner.present(actionSheet, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    override func setConstraints() {
        profileImage.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.size.equalTo(70)
        }
        
        horizonTalStackView.snp.makeConstraints { make in
            make.centerY.equalTo(profileImage)
            make.leading.equalTo(profileImage.snp.trailing).offset(10)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            
        }
        
        nickname.snp.makeConstraints { make in
            make.top.equalTo(profileImage.snp.bottom).offset(5)
            make.leading.equalTo(profileImage)
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(nickname.snp.bottom).offset(10)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.height.equalTo(40)
        }
    }
    
}

extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProvider = results.first?.itemProvider // 2
        if let itemProvider = itemProvider,
           itemProvider.canLoadObject(ofClass: UIImage.self) { // 3
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in // 4
                DispatchQueue.main.async {
                    let image = image as? UIImage
                    
                    self.profileImage.image = image
                    
                    let jpegData = image?.jpegData(compressionQuality: 0.1)
                    
                    if let data = jpegData {
                        // UImage  -> Data로 변환
                        print("data - \(data)")
                        self.selectedImageData.onNext(data)
                    }
                    
                }
            }
        } else {
            // TODO: Handle empty results or item provider not being able load UIImage
        }
    }
}
