#!/usr/bin/env ruby
require 'date'
require 'rexml/document'
include REXML # so that we don't have to prefix everything with REXML::...
 
blogger_id = "111111111111"
blog_title = "my blog"
author_name = "my name"
author_email = "noreply@blogger.com"
blog_id = "222222222222222"
blog_name = "myblog"

file = File.new( ARGV[0] )

doc = REXML::Document.new file

feed_template = %q{<?xml version="1.0" encoding="UTF-8" ?> 
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/" xmlns:gd="http://schemas.google.com/g/2005" xmlns:thr="http://purl.org/syndication/thread/1.0">
  <id>tag:blogger.com,1999:blog-#{blog_id}.archive</id> 
  <updated>2008-12-04T11:08:02.017+08:00</updated> 
  <title type="text">#{blog_title}</title> 
  <link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='http://#{blog_name}.blogspot.com/feeds/archive'/>
  <link rel='self' type='application/atom+xml' href='http://www.blogger.com/feeds/#{blog_id}/archive'/>
  <link rel='http://schemas.google.com/g/2005#post' type='application/atom+xml' href='http://www.blogger.com/feeds/#{blog_id}/archive'/>
  <link rel='alternate' type='text/html' href='http://#{blog_name}.blogspot.com/'/>
  
  <author>
  <name>#{author_name}</name> 
  <uri>http://www.blogger.com/profile/#{blogger_id}</uri> 
  <email>#{author_email}</email> 
  </author>
  <generator version="7.00" uri="http://www.blogger.com">Blogger</generator> 
  #{feed_content}
</feed>
}

entry_template = %q{
 	<entry>
  <id>tag:blogger.com,1999:blog-#{blog_id}.post-#{post_id}</id> 
  <published>#{post_date}</published>
  <updated>#{post_date}</updated>
  <category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/blogger/2008/kind#post" /> 
  <category scheme="http://www.blogger.com/atom/ns#" term="#{post_category}" /> 
  <title type="text">#{post_title}</title> 
  <content type="html"><![CDATA[#{post_content}]]></content> 
  <author>
  <name>#{author_name}</name> 
  <uri>http://www.blogger.com/profile/#{blogger_id}</uri> 
  <email>#{author_email}</email> 
  </author>
  <thr:total>#{comments_size}</thr:total> 
  </entry>
}

comment_template = %q{
  
  <entry>
   <id>tag:blogger.com,1999:blog-#{blog_id}.post-#{post_id}.comment-#{comment_id}</id>
   <published>#{comment_date}</published>
   <updated>#{comment_date}</updated>
   <category scheme='http://schemas.google.com/g/2005#kind'
             term='http://schemas.google.com/blogger/2008/kind#comment'/>
   <title type='text'><![CDATA[#{comment_content}]]></title>
   <content type='html'><![CDATA[#{comment_content}]]></content>
   <link rel='self'
         type='application/atom+xml'
         href='http://www.blogger.com/feeds/feh/comments/default/1'/>
   <author>
     #{'<name>' + "#{comment_author}" + '</name>' if comment_author}
     #{'<email>' + "#{comment_author_email}" + '</email>' if comment_author_email}
     #{'<uri>' + "#{comment_author_url}" + '</uri>' if comment_author_url}
   </author>
   <thr:in-reply-to href='http://www.blogger.com/feeds/#{blog_id}/posts/default/#{post_id}'
                    ref='tag:blogger.com,1999:blog-#{blog_id}.post-#{post_id}'
                    type='application/atom+xml'/>
  </entry>
}

entries = []
all_entries = [entries]
post_id = 0

doc.elements.each("//item") { |element| 
  post_title = element.get_text("title")
  datestr = "#{element.get_text('pubDate')}"
  post_date = DateTime.parse(datestr).strftime("%Y-%m-%dT%H:%M:%S+08:00")
  post_content = element.get_text("content:encoded")
  post_category = element.get_text("category")
  post_category = "Blogging" if post_category == "" or post_category.nil?
  post_id += 1
  
  comments = []
  comment_id = 0
  element.elements.each("wp:comment") { |comment|
    comment_author = comment.get_text("wp:comment_author")
    comment_author_email = comment.get_text("wp:comment_author_email")
    comment_author_url = comment.get_text("wp:comment_author_url")
    datestr = "#{comment.get_text('wp:comment_date_gmt')}"
    comment_date = DateTime.parse(datestr).strftime("%Y-%m-%dT%H:%M:%S+08:00")
    comment_content = comment.get_text("wp:comment_content")
    comment_id += 1
    comments << eval('%Q{' + comment_template + '}', binding)
  }

  # make sure we keep comments together with its entry while keeping within import limit
  if entries.size + comments.size + 1 > 50
    entries = []
    all_entries << entries
  end

  comments_size = comments.size
  entries << eval('%Q{' + entry_template + '}', binding)
  entries.push *comments
}


all_entries.each_with_index do |entries, i|
  feed_content = ""
  entries.each do |entry|
    feed_content += entry
  end
  destination = "p2blogger#{i}.xml"
  puts "Writing #{entries.size} entries to #{destination}"
  File.open(destination,"w") do |f|
    f.write(eval('%Q{' + feed_template + '}', binding))
  end    
end

