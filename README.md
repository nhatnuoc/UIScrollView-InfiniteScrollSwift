# UIScrollView-InfiniteScrollSwift

[![CI Status](https://img.shields.io/travis/binhvuong.2010@gmail.com/UIScrollView-InfiniteScrollSwift.svg?style=flat)](https://travis-ci.org/binhvuong.2010@gmail.com/UIScrollView-InfiniteScrollSwift)
[![Version](https://img.shields.io/cocoapods/v/UIScrollView-InfiniteScrollSwift.svg?style=flat)](https://cocoapods.org/pods/UIScrollView-InfiniteScrollSwift)
[![License](https://img.shields.io/cocoapods/l/UIScrollView-InfiniteScrollSwift.svg?style=flat)](https://cocoapods.org/pods/UIScrollView-InfiniteScrollSwift)
[![Platform](https://img.shields.io/cocoapods/p/UIScrollView-InfiniteScrollSwift.svg?style=flat)](https://cocoapods.org/pods/UIScrollView-InfiniteScrollSwift)

Infinite scroll implementation as a extension for UIScrollView. It's written by Swift. A project convert [UIScrollView-InfiniteScroll](https://github.com/pronebird/UIScrollView-InfiniteScroll) from ObjC to Swift. To use ObjC version, return to [UIScrollView-InfiniteScroll](https://github.com/pronebird/UIScrollView-InfiniteScroll).

<table>
    <tr>
        <td>
            <img src="https://raw.githubusercontent.com/nhatnuoc/UIScrollView-InfiniteScrollSwift/master/README%20images/InfiniteScroll1.gif">
        </td>
        <td>
            <img src="https://raw.githubusercontent.com/nhatnuoc/UIScrollView-InfiniteScrollSwift/master/README%20images/InfiniteScroll2.gif">
        </td>
        <td>
            <img src="https://raw.githubusercontent.com/nhatnuoc/UIScrollView-InfiniteScrollSwift/master/README%20images/InfiniteScroll3.gif">
        </td>
    </tr>
</table>

\* The content used in demo app is publicly available and provided by hn.algolia.com and Flickr. Both can be inappropriate.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

UIScrollView-InfiniteScrollSwift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'UIScrollView-InfiniteScrollSwift'
```

## Implementation

### Basics

In order to enable infinite scroll you have to provide a handler block using `addInfiniteScrollWithHandler`. The block you provide is executed each time infinite scroll component detects that more data needs to be provided.

The purpose of the handler block is to perform asynchronous task, typically networking or database fetch, and update your scroll view or scroll view subclass. 

The block itself is called on main queue, therefore make sure you move any long-running tasks to background queue. Once you receive new data, update table view by adding new rows and sections, then call `finishInfiniteScroll` to complete infinite scroll animations and reset the state of infinite scroll components.

`viewDidLoad` is a good place to install handler block.

Make sure that any interactions with UIKit or methods provided by Infinite Scroll happen on main queue. Use `DispatchQueue.main.async { ... }` in Swift to run UI related calls on main queue.

Many people make mistake by using external reference to table view or collection view within the handler block. Don't do this. This creates a circular retention. Instead use the instance of scroll view or scroll view subclass passed as first argument to handler block.


```swift
tableView.addInfiniteScroll { (tableView) -> Void in
    // update table view
            
    // finish infinite scroll animation
    tableView.finishInfiniteScroll()
}
```
### Collection view quirks

`UICollectionView.reloadData` causes contentOffset to reset. Instead use `UICollectionView.performBatchUpdates` when possible.

```swift
collectionView.addInfiniteScroll { (collectionView) -> Void in
    collectionView.performBatchUpdates({ () -> Void in
        // update collection view
    }, completion: { (finished) -> Void in
        // finish infinite scroll animations
        collectionView.finishInfiniteScroll()
    });
}
```

### Start infinite scroll programmatically

You can reuse infinite scroll flow to load initial data or fetch more using `beginInfiniteScroll(forceScroll)`. `viewDidLoad` is a good place for loading initial data, however absolutely up to you to decide.

When `forceScroll` parameter is positive, Infinite Scroll component will attempt to scroll down to reveal indicator view. Keep in mind that scrolling will not happen if user is interacting with scroll view.

```swift
tableView.beginInfiniteScroll(true)
```

### Prevent infinite scroll

Sometimes you need to prevent the infinite scroll from continuing. For example, if your search API has no more results, it does not make sense to keep making the requests or to show the spinner.

```swift
// Provide a block to be called right before a infinite scroll event is triggered.  Return YES to allow or NO to prevent it from triggering.
tableView.setShouldShowInfiniteScrollHandler { _ -> Bool in
    // Only show up to 5 pages then prevent the infinite scroll
    return currentPage < 5 
}
```

### Seamlessly preload content

Ideally you want your content to flow seamlessly without ever showing a spinner. Infinite scroll offers an option to specify offset in points that will be used to start preloader before user reaches the bottom of scroll view. 

The proper balance between the number of results you load each time and large enough offset should give your users a decent experience. Most likely you will have to come up with your own formula for the combination of those based on kind of content and device dimensions.

```swift
// Preload more data 500pt before reaching the bottom of scroll view.
tableView.infiniteScrollTriggerOffset = 500
```

### Custom indicator

You can use custom indicator instead of default `UIActivityIndicatorView`.

Custom indicator must be a subclass of `UIView` and implement protocol `InfiniteScrollIndicatorView`:

```swift
func startAnimating()
func stopAnimating()
```
```swift
let frame = CGRect(x: 0, y: 0, width: 24, height: 24)
tableView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: frame)
```

At the moment InfiniteScroll uses indicator's frame directly so make sure you size custom indicator view beforehand. Such views as `UIImageView` or `UIActivityIndicatorView` will automatically resize themselves so no need to setup frame for them.

### Remove infinite scroll

You have to remove infinite scrolling in `deinit`.

```swift
deinit {
    self.tableView.removeInfiniteScroll()
}
```

## Author

Binh Nguyen (nhatnuoc), binhvuong.2010@gmail.com

## License

UIScrollView-InfiniteScrollSwift is available under the MIT license. See the LICENSE file for more info.
