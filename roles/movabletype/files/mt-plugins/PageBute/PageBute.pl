package MT::Plugin::PageBute;
use strict;

use vars qw( $MYNAME $VERSION );
$MYNAME = 'PageBute';
$VERSION = '3.5.7';

use POSIX qw( ceil );
use File::Basename;
use File::Spec;
use MT::I18N;
use MT::Template::Context;
use Data::Dumper;

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new({
    id => $MYNAME,
    key => $MYNAME,
    name => $MYNAME,
    version => $VERSION,
    author_name => 'SKYARC System Co.,Ltd.',
    author_link => 'http://www.skyarc.co.jp/',
    doc_link => 'http://www.skyarc.co.jp/engineerblog/entry/2642.html',
    description => <<HTMLHEREDOC,
This plugin for Pagenate. Please read documentation if you use this plugin first. <br />It is possible to use it only once a page.
HTMLHEREDOC
});
MT->add_plugin( $plugin );
sub init_registry {
    my $plugin = shift;
    $plugin->registry({
         callbacks => {
            build_page => { 
                priority => 10, code => \&_page_bute,
            },
            build_file => { 
                priority => 10, code => \&_repage_bute,
            },
         },
         tags => {
            block => {
                  PageEmpty     => \&_page_empty,
                  PageContents  => \&_page_contents,
                  PageContentsHeader    => \&_if_page_,
                  PageContentsFooter    => \&_if_page_,
                  Pagination    => \&_pagination,
                  'PaginationHeader' => \&MT::Template::Context::slurp,
                  'PaginationFooter' => \&MT::Template::Context::slurp,
                  'IfPaginationCurrent?' => \&_if_pagination_,
                  'IfPaginationFirst?' => \&_if_pagination_,
                  'IfPaginationLast?' => \&_if_pagination_,
                  'IfPaginationNext?' => \&_if_pagination_,
                  'IfPaginationPrev?' => \&_if_pagination_,
                  'IfPaginationDynamic?' => \&_if_pagination_,
                  IfPageAfter    => \&_if_page_,
                  IfPageBefore  => \&_if_page_,
                  IfPageFirst   => \&_if_page_,
                  IfPageLast    => \&_if_page_,
                  IfPageNoEmpty => \&_if_page_,
            },
            function => {
                  PaginationLink => \&_pagination_link,
                  PaginationFirst => \&_pagination_link,
                  PaginationLast => \&_pagination_link,
                  PaginationPrev => \&_pagination_link,
                  PaginationNext => \&_pagination_link,
                  PageAfter     => \&_page_,
                  PageBefore    => \&_page_,
                  PageFirst     => \&_page_,
                  PageLast      => \&_page_,
                  PageCount     => \&_page_,
                  PageMaxCount  => \&_page_,
                  PageSeparator => \&_separator,
                  PageLists     => \&_page_lists,
            },
         },
    });
}
my %garbage = (
     PAGINATION        => '<!-- Pagination for PageBute -->',
     PAGEAFTER         => '<!-- AfterLink for PageBute -->',
     PAGEBEFORE        => '<!-- BeforeLink for PageBute -->',
     PAGEFIRST         => '<!-- FirstLink for PageBute -->',
     PAGELAST          => '<!-- LastLink for PageBute -->',
     Separator         => '<!-- Separator for PageBute -->',
     PageLists         => '<!-- PageLists for PageBute -->',
     Contents          => '<!-- Contents for PageBute -->',
     PAGECONTENTSHEADER        => '<!-- PageHeader for PageBute -->',
     PAGECONTENTSHEADER_END    => '<!-- PageHeader end for PageBute -->',
     PAGECONTENTSFOOTER        => '<!-- PageFooter for PageBute -->',
     PAGECONTENTSFOOTER_END    => '<!-- PageFooter end for PageBute -->',
     PAGECOUNT         => '<!-- PageCount for PageBute -->',
     PAGEMAXCOUNT      => '<!-- PageMaxCount for PageBute -->',
     IFPAGEAFTER       => '<!-- PageIfAfter for PageBute -->',
     IFPAGEAFTER_END   => '<!-- PageIfAFter end for PageBute -->',
     IFPAGEBEFORE      => '<!-- PageIfBefore for PageBute -->',
     IFPAGEBEFORE_END  => '<!-- PageIfBefore end for PageBute -->',
     IFPAGEFIRST       => '<!-- PageIfFirst for PageBute -->',
     IFPAGEFIRST_END   => '<!-- PageIfFirst_end for PageBute -->',
     IFPAGELAST        => '<!-- PageIfLast for PageBute -->',
     IFPAGELAST_END    => '<!-- PageIfLast_end for PageBute -->',
     IFPAGENOEMPTY     => '<!-- PageIfNoEmpty for PageBute -->',
     IFPAGENOEMPTY_END => '<!-- PageIfNoEmpty end for PageBute -->',
);
my %delimitor = (
     PAGEAFTER  => '&gt;',
     PAGEBEFORE => '&lt;',
     PAGEFIRST  => '&lt;&lt;',
     PAGELAST   => '&gt;&gt;',
);
sub _pagination {
   my ( $ctx , $args , $cond ) = @_;
   my $tag = uc $ctx->stash('tag');
   my $pb = $ctx->stash('PageBute') || '';

   if(!$pb) {
        my %pagebute = ();
        $pb = \%pagebute;
        $ctx->stash('PageBute',$pb);
   }

   $pb->{lc $tag . '_tokens'} = $ctx->stash('tokens');
   return $garbage{$tag};
}

sub _pagination_execute {
   my ( $ctx, $is_dynamic, $page, $min, $max, $first, $last, $base_link, $suffix, $output )=@_;
   my $tag = 'PAGINATION';
   my $pb = $ctx->stash('PageBute');
   my $tokens = $pb->{lc $tag . '_tokens'} || '';
   unless ( $tokens ) {

      $$output =~ s|\Q$garbage{$tag}\E||g;
      return;

   }
   my $builder = $ctx->stash('builder') || undef;
   $builder = MT::Builder->new unless defined $builder;

#   open my $FT , ">/tmp/debug.txt";
#   print $FT Dumper( $ctx );
#   close $FT;
   my $res = '';
   my $count = 0;
   my $vars = $ctx->{__stash}{vars} ||= {};
   for ($min .. $max) {
        $count++;
        local $vars->{__pagination_for_pagebute__} = 1;
        local $vars->{__pagination_base_link__} = $base_link;
        local $vars->{__pagination_suffix__} = $suffix;
        local $vars->{__page_number__} = $_;
        local $vars->{__if_next_page__} = $last && $page + 1 <= $last && $_ == $max;
        local $vars->{__if_prev_page__} = $page - 1 >= $first && $count == 1;
        local $vars->{__if_first_page__} = $page ne $first && $count == 1;
        local $vars->{__if_last_page__} = $last && $page ne $last && $_ == $max;
        local $vars->{__prev_page__} =  $vars->{__if_prev_page__} ? $page - 1 : $first;
        local $vars->{__next_page__} = $vars->{__if_next_page__} ? $page + 1 : $last;
        local $vars->{__first_page__} = $first;
        local $vars->{__last_page__} = $last;
        local $vars->{__first__} = $count == 1;
        local $vars->{__last__} = $_ == $max;
        local $vars->{__odd__} = ($count % 2) == 1;
        local $vars->{__even__} = ($count % 2) == 0;
        local $vars->{__counter__} = $count;
        local $vars->{__current__} = $_ == $page;
        local $vars->{__is_dynamic__} = $is_dynamic;
        defined(my $out = $builder->build($ctx, $tokens, {
          PaginationHeader => $vars->{__first__},
          PaginationFooter => $vars->{__last__},
        }))
            or return $ctx->error($builder->errstr);
        $res .= $out;
    }
    $$output =~ s|\Q$garbage{$tag}\E|$res|g;
    return;
}
sub _if_pagination_ {
   my ( $ctx , $args ,$cond ) = @_;
   my $vars = $ctx->{__stash}{vars} ||= {};
   return 0 unless $vars->{__pagination_for_pagebute__};
   my $key = {
      ifpaginationcurrent => '__current__',
      ifpaginationnext => '__if_next_page__',
      ifpaginationprev => '__if_prev_page__',
      ifpaginationfirst => '__if_first_page__',
      ifpaginationlast => '__if_last_page__',
      ifpaginationdynamic => '__is_dynamic__',
   }->{lc $ctx->stash('tag')} or return '';
   return 1 if $vars->{$key};
   return 0;
}

sub _pagination_link {
   my ( $ctx , $args , $cond ) = @_;
   my $vars = $ctx->{__stash}{vars} ||= {};
   return '' unless $vars->{__pagination_for_pagebute__};

   my $element = $args->{element} || '';
   if ( $element ) {

       return $vars->{__pagination_base_link__} if lc $element eq 'base';
       return $vars->{__pagination_suffix__} if lc $element eq 'suffix';

   }
   my $key = {
      paginationlink => '__page_number__',
      paginationfirst => '__first_page__',
      paginationlast => '__last_page__',
      paginationnext => '__next_page__',
      paginationprev => '__prev_page__',
   }->{lc $ctx->stash('tag')} or return '';
   return '' unless $vars->{$key}; 

   my $url;
   if ( $vars->{$key} == 1 ) {
      return $vars->{$key} if lc $element eq 'number';
      return sprintf "%s%s"
            ,$vars->{__pagination_base_link__}
            ,$vars->{__pagination_suffix__};
   }


   if ( $vars->{__is_dynamic__} ) {
       return $vars->{$key} if lc $element eq 'number';
       $url = sprintf "%s%s?page=%d"
            ,$vars->{__pagination_base_link__}
            ,$vars->{__pagination_suffix__}
            ,$vars->{$key};
   } else {
       return $vars->{$key} if lc $element eq 'number';
       $url = sprintf "%s_%d%s"
            ,$vars->{__pagination_base_link__}
            ,$vars->{$key}
            ,$vars->{__pagination_suffix__};
   }
   return $url;
}

sub _if_page_ {
    my ($ctx, $args, $cond) = @_;
    my $tokens = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $result = $builder->build( $ctx, $tokens, $cond )
        or return $ctx->error( $builder->errstr );
    my $tag = uc $ctx->stash('tag');
    $garbage{$tag}. $result. $garbage{$tag. '_END'};
}
sub _page_ {
    my ($ctx,$args,$cond) = @_;
    my $tag = uc $ctx->stash('tag');
    my $delim = $args->{delim} || $delimitor{$tag} || undef;
    my $pb = $ctx->stash('PageBute');
    if(!$pb) {
        my %pagebute = ();
        $pb = \%pagebute;
        $ctx->stash('PageBute',$pb);
    }
    $pb->{$tag. '_delim'} = $delim;
    $garbage{$tag} || '';
}
sub _separator { $garbage{Separator}; }
sub _page_lists {
    my ($ctx,$args,$cond) = @_;
    my $pb = $ctx->stash('PageBute');
    if(!$pb) {
        my %pagebute = ();
        $pb = \%pagebute;
        $ctx->stash('PageBute',$pb);
    }
    $pb->{page_delim} = defined $args->{delim} ? $args->{delim} : "&nbsp;\n";
    $pb->{link_start} = $args->{link_start} || q{};
    $pb->{link_close} = $args->{link_close} || q{};
    $pb->{show_always} = defined $args->{show_always} ? $args->{show_always} : 1;
    $garbage{PageLists};
}
sub _page_contents {
    my ($ctx,$args,$cond) = @_;
    my $tokens = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $pb = $ctx->stash('PageBute');
    if(!$pb) {
        my %pagebute = ();
        $pb = \%pagebute;
        $ctx->stash('PageBute',$pb);
    }
    return $ctx->error('This plugin can be applied only once in a page.') if ($pb->{loaded});
    $pb->{loaded} = 1;
    $pb->{contents} = $builder->build($ctx,$tokens,$cond);
    $pb->{count} = $args->{count} || 10;
    $pb->{navi_count} = $args->{navi_count} || '11';
    $pb->{nav_separator} = $args->{nav_separator} || '_';
    $pb->{abs2rel} = $args->{abs2rel} || 0;

    # if preview, return not splitted contents.
    if ( is_preview($ctx) ) {
        return _build_preview_contents( $pb );
    }

    return $garbage{Contents};
}

# determine if current build context is preview.
sub is_preview {
    my ( $ctx ) = @_;
    return 1 if $ctx->var('preview_template');
    return 0;
}

# create contents for preview (combinded each pages)
sub _build_preview_contents {
    my ( $pb )  = @_;

    my $count = $pb->{count} || 10;
    my @contents = split($garbage{Separator}, $pb->{contents});
    pop @contents unless $contents[$#contents] =~ m/\S/g;
    return "" unless scalar @contents;

    my $out = "";
    my $page = 0;
    my $i = 0;
    for my $content ( @contents ) {
        $i++;
        $out .= $content . "\n";
        next unless $i >= $count;
        $i = 0;
        $page++;
        $out .= "\n<p>" . '=' x 15;
        $out .= $plugin->translate('Page [_1]', $page);
        $out .= '=' x 15 . "</p>\n" ;
    }
    if ( ( scalar @contents ) % $count ) {
        $page++;
        $out .= "\n<p>" . '=' x 15;
        $out .= $plugin->translate('Page [_1]', $page);
        $out .= '=' x 15 . "</p>\n" ;
    }
    return $out;

}

sub _page_empty {
    my ($ctx,$args,$cond) = @_;
    my $tokens = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    my $pb = $ctx->stash('PageBute');
    if(!$pb) {
        my %pagebute = ();
        $pb = \%pagebute;
        $ctx->stash('PageBute',$pb);
    }
    $pb->{empty} = $builder->build($ctx,$tokens,$cond);
    return '';
}
sub _trans_encode {
    my ( $pb , $text ) = @_;
    return $text unless exists $pb->{trans_encode} && $pb->{trans_encode};
    my ( $code , $system ) = ( '' , '' );    
    return $text unless exists $pb->{trans_encode_output} && $pb->{trans_encode_output};
    return $text unless exists $pb->{trans_encode_system} && $pb->{trans_encode_system};
    $code   = $pb->{trans_encode_output};
    $system = $pb->{trans_encode_system};
    my $filter = $pb->{trans_encode_filter};
    return $filter->($text , $code ) if $filter;
    return MT::I18N::encode_text( 
       MT->version_number=~/^5/ && MT::I18N::is_utf8($text) 
          ? MT::I18N::utf8_off($text) 
          : $text,
       $system,
       $code
    );
}
sub _make_base_path {
    my ( $blog , $file , $abs2rel ) = @_;
    return undef unless $file && $blog;

    my $site_url = $blog->site_url;
    $site_url .= '/' if $site_url !~ m{/$};
    my $site_path = $blog->site_path;
    my $sep = '/';
    $sep = '\\' if $site_path =~ m{\\};
    $site_path .= $sep unless $site_path =~ m{[\\\/]$};

    my $relative_path = $file;
    $relative_path    =~ s/^\Q$site_path\E//;
    my $file_name     = basename( $file );
    $relative_path    =~ s/\Q$file_name\E$//;
    $relative_path    =~ s/\\/\//g;

    my $suffix = '';
    $suffix = $1 if $file_name =~ /\.([^\.]+)$/;
    $file_name =~ s/\.\Q$suffix\E$// if $suffix;
    $suffix = $suffix ? ".$suffix" : "";

    my $base_url = $site_url . $relative_path . $file_name;
    $base_url =~ s/^(?:http.?:\/\/[^\/]+)?(\/.*)?$/$1/ if $abs2rel;
    my $base_path = File::Spec->catdir( dirname( $file )  , $file_name );
    return  ( $base_url , $base_path , $suffix );
}

sub _page_bute {
    my ( $cb , %opt ) = @_;

    my $ctx  = $opt{Context} or return 1;
    my $blog = $opt{Blog} or return 1;
    my $file = $opt{File} or return 1;
    my $pb   = $ctx->stash('PageBute') 
        or return 1;

    my $abs2rel = $pb->{abs2rel} || 0; 
    my ( $base_url , $base_path , $suffix) = _make_base_path( $blog , $file , $abs2rel )
        or return 1;
    my $contents    = $opt{Content};
    $pb->{contents} ||= '';

    my $page_link_format   = q{<a href="%%URL%%" class="%%CLASS_NAME%%">%%LINK_NAME%%</a>};
    my $page_static_fromat = q{<span class="current_page">%%LINK_NAME%%</span>};

    my $output;
    unless( $pb->{contents} =~ m/\Q$garbage{Separator}\E/g )
    {
        $output = $$contents;
        for( keys %garbage )
        {
            next if $_ =~ m/_END/;
            if( $_ =~ m/(IF|HEADER|FOOTER)/ ) {
                 $output =~ s/\Q$garbage{$_}\E[\s\S]*?\Q$garbage{$_ . '_END'}\E//g;
                 next;
            }elsif( $_ eq 'Contents' ) {
                 my $empty = $pb->{empty} || '';
                 $output =~ s/\Q$garbage{$_}\E/$empty/g;
                 next;
            }elsif( $_ eq 'PageLists' ){
                if( $pb->{show_always} ){
                    my $empty_plists = _create_page_link( $ctx,$page_static_fromat , 1 , $base_url , $suffix , 1 , 'current_page' );
                    $output =~ s/\Q$garbage{$_}\E/$empty_plists/g;
                    next;
                }
            }
            $output =~ s/\Q$garbage{$_}\E//g;
        }
        my $opt = { 
             status => 1,
             mode => 'static',
             page => 1,
             location => '',
        };
        MT->run_callbacks('pagebute_build_page' , $ctx  , $opt , \$output );
        if ( $opt->{status} ) {
            $$contents = _trans_encode( $pb , $output );
        } else {
            $$contents = $output;
        }
        $ctx->stash('PageBute', 0);
        return 1;
    }
    $pb->{PAGEFIRST_delimitor}  ||= $delimitor{PAGEFIRST};
    $pb->{PAGEBEFORE_delimitor} ||= $delimitor{PAGEBEFORE};
    $pb->{PAGEAFTER_delimitor}   ||= $delimitor{PAGEAFTER};
    $pb->{PAGELAST_delimitor}   ||= $delimitor{PAGELAST};

    my $delim       = $pb->{page_delim};
    my $split_count = $pb->{count};

    # Ignored since the last separator.
    #
    # (sample)
    #  ...entry1..<!-- Separator for PageBute -->....entry(n)...<!-- Separator for PageBute -->...Ignore Block...
    #
    my @entries     = split /$garbage{Separator}/,  $pb->{contents};
    my $page_limit  = ceil( $#entries / $split_count );
    my $page_count  = 1;
    my $output_page_contents = '';
    my $fmgr = $blog->file_mgr;

    my $loop = 0;
    for (my $i=0; $i < $#entries; $i++) {
        if( ($i + 1) % $split_count == 0 || $i == $#entries - 1) {

            #header
            $loop
                ? $entries[$i] =~ s/\Q$garbage{PAGECONTENTSHEADER}\E[\s\S]*?\Q$garbage{PAGECONTENTSHEADER_END}\E//g
                : $entries[$i] =~ s/\Q$garbage{PAGECONTENTSHEADER}\E|\Q$garbage{PAGECONTENTSHEADER_END}\E//g;

            #footer
            $entries[$i] =~ s/\Q$garbage{PAGECONTENTSFOOTER}\E|\Q$garbage{PAGECONTENTSFOOTER_END}\E//g;
            $output_page_contents .= $entries[$i];


            $file = $page_count == 1 ? $file : $base_path . "_$page_count$suffix";
            $output = $$contents;
            $output =~ s/$garbage{Contents}/$output_page_contents/g;

            ## Make configuration page.
            my $lists  = _create_lists($page_count, $page_limit , $pb->{navi_count} );

            my ( $page_lists , $first , $before , $next , $last ) = ( '', '' , '' , '' , '' );
            ## page lists
            for ( my $i = $lists->{min_page}; $i <= $lists->{max_page}; $i++ ) {
                $page_lists .= $i == $lists->{min_page} ? '' : $delim;
                $page_lists .= $pb->{link_start};
                if( $i == $page_count ){
                    $page_lists .= _create_page_link($ctx, $page_static_fromat , $i , $base_url , $suffix , $i , 'current_page' );
                }else{
                    $page_lists .= _create_page_link($ctx, $page_link_format , $i , $base_url , $suffix , $i , 'link_page' );
                }
                $page_lists .= $pb->{link_close};
            }
                        _pagination_execute(
                             $ctx,
                             "",
                             $page_count,
                             $lists->{min_page},
                             $lists->{max_page},
                             1,
                             $lists->{last},
                             $base_url,
                             $suffix,
                             \$output
                        );
            
            #replace first link
            if ($lists->{first}) {
                $first  = _create_page_link( $ctx,$page_link_format, 1, $base_url, $suffix, $pb->{PAGEFIRST_delim}, 'link_first' );
                $first  = $pb->{link_start}. $first. $pb->{link_close};
                $output =~ s/\Q$garbage{IFPAGEFIRST}\E|\Q$garbage{IFPAGEFIRST_END}\E//g;
                $output =~ s/\Q$garbage{PAGEFIRST}\E/$first/g;
            } else {
                $output =~ s/\Q$garbage{IFPAGEFIRST}\E[\s\S]*?\Q$garbage{IFPAGEFIRST_END}\E//g;
            }
            #replace before link
            if ($lists->{before}) {
                $before = _create_page_link( $ctx,$page_link_format, $page_count - 1, $base_url, $suffix, $pb->{PAGEBEFORE_delim}, 'link_before' );
                $before = $pb->{link_start}. $before. $pb->{link_close};
                $output =~ s/\Q$garbage{IFPAGEBEFORE}\E|\Q$garbage{IFPAGEBEFORE_END}\E//g;
                $output =~ s/\Q$garbage{PAGEBEFORE}\E/$before/g;
            } else {
                $output =~ s/\Q$garbage{IFPAGEBEFORE}\E[\s\S]*?\Q$garbage{IFPAGEBEFORE_END}\E//g;
            }
            #replace next link
            if ($lists->{next}) {
                $next = _create_page_link( $ctx,$page_link_format, $page_count + 1, $base_url, $suffix, $pb->{PAGEAFTER_delim}, 'link_next' );
                $next = $pb->{link_start}. $next. $pb->{link_close};
                $output =~ s/\Q$garbage{IFPAGEAFTER}\E|\Q$garbage{IFPAGEAFTER_END}\E//g;
                $output =~ s/\Q$garbage{PAGEAFTER}\E/$next/g;
            } else {
                $output =~ s/\Q$garbage{IFPAGEAFTER}\E[\s\S]*?\Q$garbage{IFPAGEAFTER_END}\E//g;
            }
            #replace last link
            if ($lists->{last}) {
                $last   = _create_page_link( $ctx,$page_link_format, $lists->{last}, $base_url, $suffix, $pb->{PAGELAST_delim}, 'link_last' );
                $last   = $pb->{link_start}. $last. $pb->{link_close};
                $output =~ s/\Q$garbage{IFPAGELAST}\E|\Q$garbage{IFPAGELAST_END}\E|//g;
                $output =~ s/\Q$garbage{PAGELAST}\E/$last/g;
            } else {
                $output =~ s/\Q$garbage{IFPAGELAST}\E[\s\S]*?\Q$garbage{IFPAGELAST_END}\E//g;
            }

            # Page Count
            $output =~ s/\Q$garbage{PAGECOUNT}\E/$page_count/g;
            $output =~ s/\Q$garbage{PAGEMAXCOUNT}\E/$lists->{last} || $lists->{max_page}/ge;

            #replace page lists
            if (!$next && !$before && $pb->{show_always} == 0) {
                $output =~ s/\Q$garbage{PageLists}\E//g;
            }
            else {
                $output =~ s/\Q$garbage{PageLists}\E/$page_lists/g;
            }
            $output =~ s/\Q$garbage{IFPAGENOEMPTY}\E|\Q$garbage{IFPAGENOEMPTY_END}\E//g;
                        my $opt = {
                           status => 1,
                           mode => 'static',
                           page => $page_count,
                           location => 'pagination', 
                        };
                        MT->run_callbacks('pagebute_build_page' , $ctx  , $opt , \$output );
                        if ( $opt->{status} ) {
                            $output = _trans_encode( $pb , $output );
                        }
            if($page_count == 1) {
                $ctx->stash('FirstContents', $output);
                $ctx->stash('FirstFileName', $file);
            } else {
                            $fmgr->put_data($output,"${file}.new");
                            $fmgr->rename("${file}.new",$file);
                        }

            $output_page_contents = '';
            $page_count++;
        }else{
            #header
            $loop
                ? $entries[$i] =~ s/\Q$garbage{PAGECONTENTSHEADER}\E[\s\S]*?\Q$garbage{PAGECONTENTSHEADER_END}\E//g
                : $entries[$i] =~ s/\Q$garbage{PAGECONTENTSHEADER}\E|\Q$garbage{PAGECONTENTSHEADER_END}\E//g;
            #footer
            $entries[$i] =~ s/\Q$garbage{PAGECONTENTSFOOTER}\E[\s\S]*?\Q$garbage{PAGECONTENTSFOOTER_END}\E//g;
            $output_page_contents .= $entries[$i];
        }
        $loop = 0 if ++$loop >= $split_count;
    }
    $ctx->stash('PageBute', 0);
    1;
}

sub _repage_bute {
    my ($cb, %opt) = @_;

    my $ctx = $opt{Context};
    my $file = $ctx->stash('FirstFileName');
    my $contents = $ctx->stash('FirstContents');

    return 1 unless($file);

    my $blog = $ctx->stash('blog');
    my $fmgr = $blog->file_mgr;
    $fmgr->put_data($contents,"${file}.new");
    $fmgr->rename("${file}.new",$file);

    $ctx->stash('FirstFileName',0);
}

sub _create_lists {
    my ($page, $max , $navi_count ) = @_;

    my ($min_page , $max_page , $navi_side_count) = (0,0,0);
    $navi_count = $navi_count || '11';
    if ( $navi_count =~ /^\d+$/ ){
      if($navi_count == 1 || $max == 1){
        $min_page = $page;
        $max_page = $page;
      }else{
        $navi_count = $max if $navi_count > $max;
        $navi_side_count  = $navi_count > 1 ? int ($navi_count/2) : 0;
        $min_page = $page - ($navi_side_count);
        $min_page = 1 if $min_page < 1;
        $max_page = $min_page + ($navi_count - 1);
        $max_page = $max if $max_page > $max;
        $min_page = $max_page - ($navi_count - 1) if ($max_page - $min_page) < ($navi_count - 1);
      }
    }else{
       $max_page = $max;
       $min_page = 1;
    }
    my %pages = (
        first    => $page - 1 > 0 ? 1 : 0,
        before   => $page - 1 > 0 ? $page - 1 : 0,
        next     => $page + 1 <= $max ? $page + 1 : 0,
        last     => $page + 1 <= $max ? $max : 0,
        max_page => $max_page,
        min_page => $min_page
    );
    return \%pages;
}

sub _create_page_link {
    my ( $ctx , $format , $page , $base_url , $suffix , $link_name , $class_name ) = @_;
    my $url = $base_url . ( $page == 1 ? '' : "_$page" ) . $suffix;
    $url =~ s|\\|\/|g; # for windows
    my $opt = {
       status => 1,
       mode => 'static',
       format => \$format,
       page => \$page,
       url => \$url,
       title => \$link_name,
       class => \$class_name,
    };
    MT->run_callbacks('pagebute_build_link' , $ctx , $opt );
    if ( $opt->{status} ) { 
       $format =~ s!%%URL%%!$url!;
       $format =~ s!%%CLASS_NAME%%!$class_name!;
       $format =~ s!%%PAGE_NUMBER%%!$page!;
       $format =~ s!%%LINK_NAME%%!$link_name ? $link_name : ''!e;
    }
    return $format;
}

## secret functinos
sub _page_bute_cgi {
    my ( $cb , $ctx , $url , $text , $page ) = @_;

    $page = $1 || 1  if $page =~ /(\d+)/;

    my $pb = $ctx->stash( 'PageBute' ) or return 1;
    my $abs2rel = $pb->{abs2rel} || 0;
    $url =~ s/^(?:http.?:\/\/[^\/]+)?(\/.*)?$/$1/ if $abs2rel;
    my $contents = $$text || '';

    my $page_link_format  = q{<a href="%%URL%%%%PARAM%%%%PAGE%%" class="%%CLASS_NAME%%">%%PAGENAME%%</a>};
    my $page_link_format_static = q{<span class="%%CLASS_NAME%%">%%PAGENAME%%</span>};
    unless( $pb->{contents} =~ m/\Q$garbage{Separator}\E/g )
    {
        for( keys %garbage )
        {
            next if $_ =~ m/_END/;
            if( $_ =~ m/(IF|HEADER|FOOTER)/ ) {
                 $contents =~ s/\Q$garbage{$_}\E[\s\S]*?\Q$garbage{$_ . '_END'}\E//g;
                 next;
            }elsif( $_ eq 'Contents' ) {
                 my $empty = $pb->{empty} || '';
                 $contents =~ s/\Q$garbage{$_}\E/$empty/g;
                 next;
            }elsif( $_ eq 'PageLists' ){
                if( $pb->{show_always} ){
                    my $empty_plists = _create_page_link_cgi( $ctx , $page_link_format_static , 1 , $url , 1 , 'current_page' );
                    $contents =~ s/\Q$garbage{$_}\E/$empty_plists/g;
                    next;
                }
            }
            $contents =~ s/\Q$garbage{$_}\E//g;
        }
        my $opt = {
            status => 1,
            mode => 'dynamic',
            location => '',
        };
        MT->run_callbacks('pagebute_build_page' , $ctx  , $opt , \$contents );
        $$text = $contents;
        $ctx->stash('PageBute', 0); ## reset;
        return 1;
    }
    $pb->{PAGEFIRST_delimitor}  ||= $delimitor{PAGEFIRST};
    $pb->{PAGEBEFORE_delimitor} ||= $delimitor{PAGEBEFORE};
    $pb->{PAGEAFTER_delimitor}   ||= $delimitor{PAGEAFTER};
    $pb->{PAGELAST_delimitor}   ||= $delimitor{PAGELAST};
    my @entries     = split /$garbage{Separator}/ , $pb->{contents};
    my $entry_count = $#entries;
    my $count = $pb->{count} || 10;

    my $page_limit  = $entry_count >= $count
         ? ceil( $entry_count / $count )
         : 1;
    $page = $page < 1
         ? 1
         : $page_limit >= $page
              ? $page
              : $page_limit;

    my $out = '';
    my $start = ( $page - 1 )  * $count;
    my $last  = $start + ( $count - 1);
    $last = $entry_count - 1 if $last >= $entry_count;

    $entries[ $start ] =~ s/\Q$garbage{PAGECONTENTSHEADER}\E|\Q$garbage{PAGECONTENTSHEADER_END}\E//g;
    $entries[ $last ]  =~ s/\Q$garbage{PAGECONTENTSFOOTER}\E|\Q$garbage{PAGECONTENTSFOOTER_END}\E//g;

    for my $outbuff ( @entries[ $start..$last ] ){
        $outbuff =~ s/\Q$garbage{PAGECONTENTSHEADER}\E[\s\S]*?\Q$garbage{PAGECONTENTSHEADER_END}\E//g;
        $outbuff =~ s/\Q$garbage{PAGECONTENTSFOOTER}\E[\s\S]*?\Q$garbage{PAGECONTENTSFOOTER_END}\E//g;
        $out .= $outbuff;
    }
    $contents =~ s/$garbage{Contents}/$out/g;
    my $pinfo = _create_lists( $page , $page_limit , $pb->{navi_count} );
    $out = '';
    for ( $pinfo->{min_page} .. $pinfo->{max_page} )
    {
         $out .= $pb->{page_delim} || ''
             if $_ ne $pinfo->{min_page};
         $out .= _create_page_link_cgi( $ctx , 
            $_ == $page
                 ? $page_link_format_static
                 : $page_link_format, 
            $_,
            $url,
            $_,
            $_ == $page
                 ? 'current_page'
                 : 'link_page',
        );
    }
    _pagination_execute( 
          $ctx , 
          'dynaimc',
          $page,
          $pinfo->{min_page},
          $pinfo->{max_page},
          1,
          $pinfo->{last},
          $url,
          "",
          \$contents,
    );

    $out .= _create_page_link_cgi( $ctx , $page_link_format_static , 1 , $url , 1 , 'current_page' ) unless $out;
    if (!$pinfo->{next} && !$pinfo->{before} && $pb->{show_always} == 0) {
        $contents =~ s/\Q$garbage{PageLists}\E//g;
    }
    else {
        $out = $pb->{link_start} . $out . $pb->{link_close};
        $contents =~ s/\Q$garbage{PageLists}\E/$out/g;
    }

    if ($pinfo->{first}) 
    {
        $out  = _create_page_link_cgi( $ctx , $page_link_format, 1, $url, $pb->{PAGEFIRST_delim}, 'link_first' );
        $out  = $pb->{link_start}. $out. $pb->{link_close};
        $contents =~ s/\Q$garbage{IFPAGEFIRST}\E|\Q$garbage{IFPAGEFIRST_END}\E//g;
        $contents =~ s/\Q$garbage{PAGEFIRST}\E/$out/g;
    }
    else
    {
        $contents =~ s/\Q$garbage{IFPAGEFIRST}\E[\s\S]*?\Q$garbage{IFPAGEFIRST_END}\E//g;
    }

    if ($pinfo->{before}) 
    {
        $out = _create_page_link_cgi( $ctx , $page_link_format, $page - 1  , $url , $pb->{PAGEBEFORE_delim}, 'link_before' );
        $out = $pb->{link_start}. $out. $pb->{link_close};
        $contents =~ s/\Q$garbage{IFPAGEBEFORE}\E|\Q$garbage{IFPAGEBEFORE_END}\E//g;
        $contents =~ s/\Q$garbage{PAGEBEFORE}\E/$out/g;
    }
    else
    {
        $contents =~ s/\Q$garbage{IFPAGEBEFORE}\E[\s\S]*?\Q$garbage{IFPAGEBEFORE_END}\E//g;
    }

    if ($pinfo->{next}) 
    {
        $out = _create_page_link_cgi( $ctx , $page_link_format, $page + 1, $url , $pb->{PAGEAFTER_delim}, 'link_next' );
        $out = $pb->{link_start}. $out. $pb->{link_close};
        $contents =~ s/\Q$garbage{IFPAGEAFTER}\E|\Q$garbage{IFPAGEAFTER_END}\E//g;
        $contents =~ s/\Q$garbage{PAGEAFTER}\E/$out/g;
    }
    else
    {
        $contents =~ s/\Q$garbage{IFPAGEAFTER}\E[\s\S]*?\Q$garbage{IFPAGEAFTER_END}\E//g;
    }

    if ($pinfo->{last}) {
        $out   = _create_page_link_cgi( $ctx , $page_link_format, $pinfo->{last}, $url , $pb->{PAGELAST_delim}, 'link_last' );
        $out   = $pb->{link_start}. $out. $pb->{link_close};
        $contents =~ s/\Q$garbage{IFPAGELAST}\E|\Q$garbage{IFPAGELAST_END}\E//g;
        $contents =~ s/\Q$garbage{PAGELAST}\E/$out/g;
    } else {
        $contents =~ s/\Q$garbage{IFPAGELAST}\E[\s\S]*?\Q$garbage{IFPAGELAST_END}\E//g;
    }

    # Page Count
    $contents =~ s/\Q$garbage{PAGECOUNT}\E/$page/g;
    $contents =~ s/\Q$garbage{PAGEMAXCOUNT}\E/$pinfo->{last} || $pinfo->{max_page}/ge;
    $contents =~ s/\Q$garbage{IFPAGENOEMPTY}\E|\Q$garbage{IFPAGENOEMPTY_END}\E//g;

    my $opt = {
       status => 1,
       mode => 'dynamic',
       page => $page,
       location => 'pagination',
    };
    MT->run_callbacks('pagebute_build_page' , $ctx  , $opt , \$contents );
    $$text = $contents;
    $ctx->stash( 'PageBute' , 0 ); ## reset
    return 1;
}

sub _create_page_link_cgi {
    my ( $ctx , $format , $page , $url , $page_name , $class_name ) = @_;
    my $param = '?page=';
    if ( $page == 1 ) {
       $param = '';
       $page  = '';
    }
    my $opt = {
       status => 1,
       mode => 'dynamic',
       format => \$format,
       page => \$page,
       query => \$param,
       url => \$url,
       title => \$page_name,
       class => \$class_name,
    };
    MT->run_callbacks('pagebute_build_link' , $ctx,$opt );
    if ( $opt->{status} ) {
       $format =~ s!%%URL%%!$url!g;
       $format =~ s!%%CLASS_NAME%%!$class_name!g;
       $format =~ s!%%PARAM%%!$param!g;
       $format =~ s!%%PAGE%%!$page!g;
       $format =~ s!%%PAGENAME%%!$page_name!g;
    }
    return $format;
}

1;
__END__
