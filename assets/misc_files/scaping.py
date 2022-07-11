# Import our scraping tools:
# Import Splinter and BeautifulSoup
from splinter import Browser
from bs4 import BeautifulSoup as soup
from webdriver_manager.chrome import ChromeDriverManager
import pandas as pd
import datetime as dt


# Set the executable path and initialize a browser:
# Set up Splinter
def scrape_all():
    # Initiate headless driver for deployment
    executable_path = {'executable_path': ChromeDriverManager().install()}
    browser = Browser('chrome', **executable_path, headless=True)

    news_title, news_paragraph = mars_news(browser)

    # Run all scraping functions and store results in a dictionary
    data = {
        "news_title": news_title,
        "news_paragraph": news_paragraph,
        "featured_image": featured_image(browser),
        "facts": mars_facts(),
        "hemispheres": hemisphere(browser),
        "last_modified": dt.datetime.now()
    }

    # Stop webdriver and return data
    browser.quit()
    return data

def mars_news(browser):
    # Visit the mars nasa news site
    url = 'https://data-class-mars.s3.amazonaws.com/Mars/index.html'
    browser.visit(url)
    # Optional delay for loading the page
    browser.is_element_present_by_css('div.list_text', wait_time=1)

    # Convert the browser html to a soup object and then quit the browser
    # Set up the HTML parser:
    html = browser.html
    news_soup = soup(html, 'html.parser')

    # Add try/except for error handling
    try:
        slide_elem = news_soup.select_one('div.list_text')
        ##print(slide_elem)

        #  Assign the title and summary text to variables we'll reference later:
        ##slide_elem.find('div', class_='content_title')

        # Use the parent element to find the first `a` tag and save it as `news_title`
        news_title = slide_elem.find('div', class_='content_title').get_text()
        #print(news_title)

        #  The article summary (teaser):
        # Use the parent element to find the paragraph text
        news_p = slide_elem.find('div', class_='article_teaser_body').get_text()
        ##news_p
    except AttributeError:
        return None, None

    return news_title, news_p


# # Scrape Mars Data: Featured Image:
# ### Featured Images

def featured_image(browser):
    # Visit URL
    url = 'https://data-class-jpl-space.s3.amazonaws.com/JPL_Space/index.html'
    browser.visit(url)

    # Find and click the full image button
    full_image_elem = browser.find_by_tag('button')[1]
    full_image_elem.click()

    # Parse the resulting html with soup
    html = browser.html
    img_soup = soup(html, 'html.parser')

    # Add try/except for error handling
    try:
        # Find the relative image url
        img_url_rel = img_soup.find('img', class_='fancybox-image').get('src')
        ## img_url_rel
    except AttributeError:
        return None

    # Use the base URL to create an absolute URL
    img_url = f'https://data-class-jpl-space.s3.amazonaws.com/JPL_Space/{img_url_rel}'

    return img_url


# # Scrape Mars Data: Mars Facts:

def mars_facts():
    # Add try/except for error handling
    try:
        # Use 'read_html' to scrape the facts table into a dataframe
        df = pd.read_html('https://data-class-mars-facts.s3.amazonaws.com/Mars_Facts/index.html')[0]

    except BaseException:
        return None

    # Assign columns and set index of dataframe    
    df.columns=['description', 'Mars', 'Earth']
    df.set_index('description', inplace=True)
    ## df

    # Convert our DataFrame back into HTML-ready code using the .to_html() function:
    return df.to_html(classes="table table-striped")


######## Challenge #######
def hemisphere(browser):
    url='https://marshemispheres.com/'
    browser.visit(url)

    # Set up the HTML parser:    
    image_html = browser.html
    image_soup = soup(image_html, 'html.parser')

# Retrieve all items for hemispheres information:
    picture_results = image_soup.find_all( 'div', class_='item')

# 2. Create a list to hold the images and titles.
    hemisphere_image_urls = []

# Create loop to scrape through all hemisphere information
    for hemis in picture_results:
        hemisphere = {}
        titles = hemis.find('h3').text
    
    # create link for full image
        link_ref = hemis.find('a', class_='itemLink product-item')['href']
    
    # Use the base URL to create an absolute URL and browser visit
        browser.visit(url + link_ref)
    
    # 3. Write code to retrieve the image urls and titles for each hemisphere.
    # Set up the HTML parser:    
        images_html = browser.html
        images_soup = soup(images_html, 'html.parser')
    
        img_url = images_soup.find('img', class_='wide-image')['src']
    
        #print(titles)
        #print(img_url)
    # append list
        hemisphere['img_url'] = f'https://marshemispheres.com/{img_url}'
        hemisphere['titles'] = titles
        hemisphere_image_urls.append(hemisphere)
        # Go Back
        browser.back()
    return hemisphere_image_urls

######## End #########
if __name__ == "__main__":
    # If running as script, print scraped data
    print(scrape_all())

# End the automated browsing session:
# browser.quit()
